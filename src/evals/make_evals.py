#!/usr/bin/env python
import json
import itertools
import random
from typing import Union, List
import pandas as pd

import utils

def make_pid(pid: str, **params) -> str:
    """
    Join prompt template with params to make id

    Args:
        pid (str): Prefix for id

    Returns:
        str: id string
    """
    return pid+'_'+'_'.join([v for k,v in params.items()]) if params else pid


def filter_vars(
    var:dict, 
    n_prompt:Union[int,list]=4,
    n_subject:Union[int,list]=4,
    n_location:Union[int,list]=50, 
    n_mp:Union[int,list]=50, 
    n_persona:Union[int,list]=2, 
    mode:str="int") -> dict:
    """
    Filter given var dict down to specified options. Default parameters will return the full eval set with no filtering. 
    Can pass number of options to randomly select as:
    int (e.g. n_subject=2, ... mode="int") - selects 2 values randomly from possible values for subject.
    list (e.g. n_subject=[0,1], ... mode="list") - selects subject values by numerical index, e.g. here the first and second.
    id (e.g. n_subject=["china", "drugs"], ... mode="id") - selects subject values by id as specified in variables.json

    Args:
        var: Dictionary containing dictionary of variables to filter.
        n_prompt (int, list, optional): Prompts to include. Defaults to 4 (all prompts)
        n_subject (int, list, optional): Subjects to include. Defaults to 4 (all subjects)
        n_location (int, list, optional): Locations to include. Defaults to 50 (all locations)
        n_mp (int, list, optional): MPs to include (only used in "mps" use case). Defaults to 50 (all mps)
        n_persona (int, list, optional): Personas to use. Defaults to 2 (all personas).
        mode (str, optional): How to choose variable values. Defaults to "int".
    """
    args = locals()

    def filter_int(x, f):
        return {key:x[key] for key in random.sample(list(x.keys()),f)}
    def filter_list(x, f):
        return {key: x[key] for key in [list(x.keys())[i] for i in f]}
    def filter_id(x, f):
        return {k:v for k,v in x.items() if k in f}
    
    fmap = {'int': filter_int, 'list': filter_list, 'id': filter_id}

    fvar = var.copy()
    # iterate over variables
    for vname, vdict  in fvar.items():
        if vname!="tweet":
        # check if no filtering is needed, i.e. args match size of variable options
            if (
                mode=="int" and args[f"n_{vname}"] == len(vdict.keys())
            ) or (
                mode in ["list", "id"] and len(args[f"n_{vname}"]) == len(vdict.keys())
            ):
                print(f"n_{vname} matches size of variables - no filtering")
                continue
            else:
                # apply chosen filter
                fvar[vname] = fmap[mode](vdict, args[f"n_{vname}"])
    # handle tweet - it should match subject
    fvar['tweet'] = {key: fvar['tweet'][key] for key in fvar['subject'].keys()}
    return fvar


def make_var_prompts(var:dict) -> List[dict]:
    """
    Generate set of prompts based on given possible values for variables

    Args:
        var (dict): Variable name (keys) and possible values (values) as dict(id:value)

    Returns:
        list: List of resulting prompts and metadata as dictionaries
    """
    data = []
    # for each possible prompt
    for pid, prompt in var['prompt'].items():
        # get variables that are used in prompt - exclude "tweet" as this is equivalent to "subject"
        pvars = {k:v for k,v in var.items() if '{'+k+'}' in prompt if k!='tweet'}

        # create combinations of variable values - these values are the ids, not the actual strings
        vcombos = [
            {k: combo[i] for i, k in enumerate(pvars.keys())}
            for combo in itertools.product(*list(pvars.values()))
        ]

        # create experiments for each variable combination
        for vc in vcombos:
            vcprompt = prompt

            # replace string placeholders
            for k,v in vc.items():
                vcprompt = vcprompt.replace('{'+k+'}', pvars[k][v])
            if '{tweet}' in prompt: 
                vcprompt = vcprompt.replace('{tweet}', var['tweet'][vc['subject']])

            # create experiment dict including id using variable value ids
            exp = dict(id=make_pid(pid, **vc), prompt=vcprompt, task=pid)
            exp.update(vc)
            data.append(exp)

    return data


def add_params(data:List[dict], params:dict) -> List[dict]:
    """
    Given list of prompt dicts, add params and permutations of possible values

    Args:
        data (List[dict]): List of prompts to add params to
        params (dict): Param name (key) and possible values (value)

    Returns:
        List[dict]: List of prompt/param permutations
    """
    newdata = []
    # remove max_tokens for permutations
    pvars = {k:v for k,v in params.items() if k!='max_tokens'}
    # make permutations of remaining params
    pcombos = [
        {k: combo[i] for i, k in enumerate(pvars.keys())}
        for combo in itertools.product(*list(pvars.values()))
    ]
    # iterate over prompts
    for d in data:
        # iterate over possible param permutations
        for pc in pcombos:
            p = pc.copy()
            # set max_tokens value
            p.update({'max_tokens':params['max_tokens']})

            d2 = d.copy()
            # add params to prompt dict
            d2.update({'parameters':p})
            # update id to include params
            d2['id'] = d2['id'] + '_' + '_'.join([
                f"temp{100*float(p['temperature']):.0f}", 
                f"topp{100*float(p['top_p']):.0f}", 
                f"topk{p['top_k']}"
            ])
            newdata.append(d2)

    return newdata


def rename_params(params:dict, param_map:dict, api:str) -> dict: 
    """
    Rename params based on given mapping/value

    Args:
        params (dict): Params to be renamed (keys)
        param_map (dict): Mapping of param->api->newname
        api (str): api to base renaming off
    """
    return {
        param_map[k][api]:v
        for k,v in params.items() 
        if param_map[k][api]!=""
    }


def add_models(data:List[dict], models:dict, param_map:dict=None, sort_by_model:bool=True) -> List[dict]:
    """
    Given list of prompt dicts, add models, and optionally rename params based on api

    Args:
        data (List[dict]): List of prompts to add params to
        models (dict): Model (key) and info (values)
        param_map (dict, optional): Mapping of param->api->newname. Defaults to None.

    Returns:
        List[dict]: List of prompt/model permutations
    """
    newdata = []

    for d in data:
        # iterate over modles
        for m, minfo in models.items():
            d2 = d.copy()
            # set model data 
            d2['api'] = minfo['api']
            d2['model_name'] = minfo['model_id']

            if minfo['api'] == 'azure-openai':
                d2['mode'] = minfo['mode']

            # add safety filter arg for gemini
            if minfo['api'] == 'gemini':
                d2['safety_filter']='none'

            # map param names based on api
            if param_map is not None:
                d2['parameters'] = rename_params(d2['parameters'], param_map, minfo['api'])
            # add model to id
            d2['id'] = d2['id'] + '_' + m.lower().replace(' ', '').replace('.','').replace('-','')
            newdata.append(d2)
    
    if sort_by_model:
        newdata = pd.DataFrame(newdata).sort_values(by=['model_name','api']).to_dict(orient='records')

    return newdata


def make_eval(var:dict, params:dict=None, models:dict=None, param_map:dict=None, return_df:bool=True) -> list:
    """
    Create list of dictionaries representing individual filled prompts, using variables from var dict, and optional model/parameter values.

    Args:
        var (dict): Variables to generate prompts from
        params (dict, optional): Model parameters to generate permutations for. Defaults to None
        models (dict, optional): Models to generate permutations for. Defaults to None
        param_map (dict, optional): Mapping of parameter names for different model providers. Defaults to None

    Returns:
        list: List of dictionaries of filled prompts and variables
    """
    if models is not None and params is not None and param_map is None: 
        raise Exception("param_map must be passed if params and models are passed.")

    data = make_var_prompts(var)

    if params is not None:
        data = add_params(data, params)
        if models is not None:
            data = add_models(data, models, param_map)
    else:
        if models is not None:
            data = add_models(data, models)
        
    return pd.DataFrame(data) if return_df else data


def export_batch_llm(data:pd.DataFrame, path:str):
    """
    Export eval df to jsonl file for use in batch-llm

    Args:
        data (pd.DataFrame): Eval data to export
        path (str): Path to .jsonl file to export to
    """
    utils.df_to_jsonl(data[
        [c for c in ['id','prompt','api','model_name','safety_filter','mode','parameters'] if c in data.columns]
    ], path)


if __name__=="__main__":
    # TODO: Add argparse
    for use_case in['mps','voting','baseline']:
        var = json.load(open(f"data/evals/{use_case}/variables.json","r"))
        params = json.load(open(f"data/evals/parameters.json", "r"))
        param_map = json.load(open(f"data/evals/param_map.json", "r"))
        models = pd.read_csv('data/evals/models.csv').set_index('model').to_dict('index')

        # make pure prompts (no params/models)
        prompts = pd.DataFrame(make_var_prompts(var))
        prompts.to_csv(f"data/evals/{use_case}/prompts.csv", encoding='utf-8-sig', index=False)

        # make full eval
        data = make_eval(
            var=var,
            params=params,
            models=models,
            param_map=param_map,
            return_df=True
        )
        # save to csv and jsonlines
        data.to_csv(f"data/evals/{use_case}/eval.csv", encoding='utf-8-sig', index=False)
        export_batch_llm(data, f"data/evals/{use_case}/eval.jsonl")
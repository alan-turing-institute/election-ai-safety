import pandas as pd
import jsonlines

def jsonl_to_df(path:str):
    """
    Read jsonlines file to pandas dataframe

    Args:
        path (str): Path to .jsonl file

    Returns:
        pd.DataFrame: dataframe of contents of jsonl file
    """
    data = []
    with jsonlines.open(path) as reader:
        for line in reader:
            data.append(line)
    return pd.DataFrame(data)

def df_to_jsonl(df:pd.DataFrame, path:str, remove_nan:bool=True):
    """
    Write pandas dataframe to jsonlines file

    Args:
        df (pd.DataFrame): Dataframe to write to file
        path (str): Path to .jsonl file to write to
        remove_nan (bool, optional): Whether to remove keys with null values in each entry. Defaults to True.
    """
    with jsonlines.open(path, mode='w') as writer:
        for _, row in df.iterrows():
            if remove_nan: 
                writer.write({k:v for k,v in row.to_dict().items() if pd.notnull(v)})
            else:
                writer.write(row.to_dict())
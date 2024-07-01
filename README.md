# Election AI Safety Paper (name TBC)

*Measuring compliance and "humanness" of Large Language Models for election misinformation generation.*

This study uses [**prompto**](https://github.com/alan-turing-institute/prompto).

### 📏 <span style="font-variant:small-caps;">DisElect</span> Eval

Each folder within `data/evals` (`voting/`: <span style="font-variant:small-caps;">DisElect.VT</span>, `mps/`: <span style="font-variant:small-caps;">DisElect.MP</span> , `baseline/`: <span style="font-variant:small-caps;">DisElect.BL</span>) contains **templates and variables** (`data/evals/*/variables.json`) used to construct **sets of prompts** (`data/evals/*/prompts.csv`), files for input to [**prompto**](https://github.com/alan-turing-institute/prompto) (`data/evals/*/eval.jsonl`), and **results** (`data/evals/*/results.csv`) - results contain only judgements and not full model responses.


`src/make_evals.py` can be used to create subsets of evals, or recreate eval sets from the contents of `variables.json`, `data/evals/models.csv`, and `data/evals/params.json`.

Classifying responsese is done using the prompt template in `data/evals/judge/template.txt` on GPT-3.5 Turbo. `src/evals/judge.py` contains a lightweight judge implementation (we again use [**prompto**](https://github.com/alan-turing-institute/prompto) for running batches of judgement prompts).

Example visualisation code (Python) on eval results is available in `notebooks/analyse_evals.ipynb`.

### 🤖 Experiments

The resulting counts and proportions of human assigments for each experiment (exp_MP<sub>L</sub>, exp_MP<sub>R</sub>, exp_VT) are available in `data/experiments/*/proportions.csv`.

Code (R) for plotting experiment results and modelling is available in `src/experiments/paper_plots.R` and `src/experiments/regression.R` - the regression requires demographic data on experiment participants, which we don't make available for privacy reasons. 

### Models:

Available in `data/models/csv`

| Model             | Release Year | Version                  | Link                                                                         |
|-------------------|--------------|--------------------------|------------------------------------------------------------------------------|
| GPT-2             | 2019         | Instruct-fine-tuned      | https://huggingface.co/vicgalle/gpt2-open-instruct-v1                        |
| T5                | 2020         | XL (2.85B)               | https://huggingface.co/google/t5-v1_1-xl                                     |
| GPT-Neo           | 2021         | 2.7B                     | https://huggingface.co/EleutherAI/gpt-neo-2.7B                               |
| Flan-T5           | 2022         | XL (2.85B)               | https://huggingface.co/google/flan-t5-xl                                     |
| GPT-3.5 (t-d-003) | 2022         | davinci-003              | n/a                                                                          |
| GPT-3.5 Turbo     | 2023         | gpt-3.5-turbo            | https://platform.openai.com/docs/models/gpt-3-5-turbo                        |
| GPT-4             | 2023         | gpt-4-0613               | https://platform.openai.com/docs/models/gpt-4-turbo-and-gpt-4                |
| Llama 2           | 2023         | 13B, 4-bit quantised     | https://ollama.com/library/llama2:13b                                        |
| Mistral           | 2023         | 7B, 4-bit quantised      | https://ollama.com/library/mistral:7b                                        |
| Gemini 1.0 Pro    | 2023         | gemini-1.0-pro-002       | https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/gemini |
| Phi-2             | 2023         | 2.7B, 4-bit quantised    | https://ollama.com/library/phi:2.7b                                          |
| Gemma             | 2024         | v1.1 7B, 4-bit quantised | https://ollama.com/library/gemma:v1.1                                        |
| LLama 3           | 2024         | 70B, 4-bit quantised     | https://ollama.com/library/llama3:70b                                        |


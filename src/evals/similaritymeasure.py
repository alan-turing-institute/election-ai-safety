from abc import ABC, abstractmethod

import pandas as pd
import numpy as np
import re

import warnings
warnings.filterwarnings('ignore')

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

import spacy

from sentence_transformers import SentenceTransformer, util

import tiktoken
from openai import AzureOpenAI

pd.options.mode.chained_assignment = None

nlp = spacy.load("en_core_web_md")


def clean_text(s):
    s = re.sub(r'\s+', ' ', s).strip()
    s = re.sub(r". ,","",s)
    s = s.replace("..",".")
    s = s.replace(". .",".")
    s = s.replace("\n", "")
    s = s.lstrip(".")
    s = s.lstrip(",")
    s = s.strip()
    return s


class SimilarityMeasure(ABC):
    """
    Abstract base class for string similarity measures.
    """

    @abstractmethod
    def vectorize(self, texts: list) -> np.ndarray:
        """
        Transforms a list of strings into a vector representation suitable for the chosen similarity measure.
        """
        pass


    def clean_input(self, texts: list):
        """
        Apply clean_text to input strings
        """
        return [clean_text(t) for t in texts]
    

    def similarity_matrix(self, texts: list):
        """
        Get similarity matrix for list of strings.
        """
        texts = self.clean_input(texts)
        vectors = self.vectorize(texts)
        return cosine_similarity(vectors)


    def pairwise_similarity(self, texts: list, return_avg: bool = False):
        """
        Calculate upper triangle of similarity matrix for list of strings. Return list or mean
        """
        similarity_matrix = self.similarity_matrix(texts)
        psim = similarity_matrix[np.triu_indices_from(similarity_matrix, k=1)]
        if return_avg: 
            return np.mean(psim)
        else: 
            return psim
        

    def similarity(self, a:str, b:str):
        """
        Get similarity for measure between two individual strings
        """
        return self.pairwise_similarity([a,b],False)[0]
    

    def similarity_with_group(self, string: str, group: list, remove_subject: bool = False, return_avg: bool = False):
        """
        Calculate pairwise similarity between a single string and a group of strings.
        """
        if remove_subject:
            group = [g for g in group if g != string]

        similarity_matrix = self.similarity_matrix([string] + group)
        similarities = similarity_matrix[0][1:].tolist()  # Get first row (excluding itself)
        if return_avg: 
            return np.mean(similarities)
        else: 
            return similarities


    def all_group_similarities(self, group: list, ids: list = None) -> dict:
        """
        Calculates average similarity for each member of the group with the rest of the group.
        """
        similarity_matrix = self.similarity_matrix(group)
        avg_similarities = {
            # group[i]: np.mean(similarity_matrix[i, :i] + similarity_matrix[i, i + 1:])
            group[i] if ids is None else ids[i]: np.mean(similarity_matrix[i][np.arange(len(group))!=i])
            for i in range(len(group))
        }
        return avg_similarities



class TfIdfSimilarity(SimilarityMeasure):
    """
    Class to calculate similarity using TF-IDF and cosine similarity.
    """

    def vectorize(self, texts: list) -> np.ndarray:
        """
        Transforms a list of strings into TF-IDF vectors.
        """
        vectorizer = TfidfVectorizer(token_pattern='(?u)\\b\\w+\\b')
        return vectorizer.fit_transform(texts)


class SpacyEmbeddingSimilarity(SimilarityMeasure):
    """
    Class to calculate similarity using Spacy Embeddings.
    """

    def vectorize(self, texts: list) -> np.ndarray:
        """
        Transforms a list of strings into Spacy word embeddings.
        """
        embeddings = [nlp(text).vector for text in texts]
        return np.array(embeddings)


class SentenceEmbeddingSimilarity(SimilarityMeasure):
    """
    Class to calculate similarity using SentenceTransformer's BERT model.
    """

    def __init__(self, model='all-MiniLM-L6-v2'):
        self.model = SentenceTransformer(model)

    def vectorize(self, texts: list) -> np.ndarray:
        """
        Transforms a list of strings into SentenceTransformer BERT embeddings.
        """
        embeddings = self.model.encode(texts)
        return embeddings
    

class OpenAIEmbeddingSimilarity(SimilarityMeasure):
    """
    Class to calculate similarity using SentenceTransformer's BERT model.
    """

    def __init__(self, key: str, endpoint: str, deployment: str, token_limit=8192, tokenizer="cl100k_base"):
        self.client = AzureOpenAI(
            api_key=key,
            api_version="2024-02-01",
            azure_endpoint=endpoint
        )
        self.deployment = deployment
        self.tokenizer = tiktoken.get_encoding(tokenizer)
        self.token_limit = token_limit


    def check_length(self, texts: list):
        """
        Check for strings that exceed token limit
        """
        n_tokens = [len(self.tokenizer.encode(t)) for t in texts]
        if any([nt>self.token_limit for nt in n_tokens]):
            for i in range(0,len(n_tokens)):
                if n_tokens[i]>self.token_limit:
                    raise Exception(f"texts[{i}] exceeds token limit ({self.token_limit})")


    def vectorize(self, texts: list) -> np.ndarray:
        """
        Transforms a list of strings into SentenceTransformer BERT embeddings.
        """
        self.check_length(texts)
        embeddings = self.client.embeddings.create(input=texts, model=self.deployment)
        return np.array([e.embedding for e in embeddings.data])
    
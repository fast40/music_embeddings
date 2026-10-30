import re
from collections import Counter

import torch

with open("bible_clean.txt", "r") as file:
    text = file.read()

text = re.sub(r"[^A-Za-z\s]", "", text)
text = text.upper()
words = text.split()

counter = Counter(words)
vocab = [word for word, _ in counter.most_common()]
stoi = {word: i for i, word in enumerate(vocab)}

W_target = torch.load("embeddings.pt", map_location="cpu", weights_only=False)
embeddings = W_target.weight.detach()
embeddings = embeddings / embeddings.norm(dim=-1, keepdim=True)

while True:
    word = input("word: ").strip().upper()
    if word not in stoi:
        print("not in vocab")
        continue

    similarities = embeddings @ embeddings[stoi[word]]
    top = similarities.topk(11).indices[1:]

    for i in top:
        print(f"{vocab[i]:<15} {similarities[i]:.3f}")

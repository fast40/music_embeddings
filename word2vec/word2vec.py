import re
from collections import Counter

import torch
from torch import nn, optim

torch.manual_seed(1337)

with open("bible_clean.txt", "r") as file:
    text = file.read()

text = re.sub(r"[^A-Za-z\s]", "", text)
text = text.upper()
words = text.split()

counter = Counter(words)
vocab = [word for word, _ in counter.most_common()]
stoi = {word: i for i, word in enumerate(vocab)}

y_train = torch.tensor([stoi[word] for word in words])

vocab_size = len(vocab)
d_embed = 128
n_words_to_left_and_right = 2
batch_size = 1024

W_target = nn.Embedding(vocab_size, d_embed)
W_neighbor = nn.Embedding(vocab_size, d_embed)

optimizer = optim.Adam([*W_target.parameters(), *W_neighbor.parameters()], lr=1e-2)

for epoch in range(10000):
    min_index = n_words_to_left_and_right
    max_index = len(y_train) - n_words_to_left_and_right

    target_i = torch.randint(min_index, max_index, (batch_size,))

    offsets = torch.cat(
        [
            torch.arange(-n_words_to_left_and_right, 0),
            torch.arange(1, n_words_to_left_and_right + 1),
        ]
    )

    neighbor_i = target_i[..., torch.newaxis] + offsets  # (B x N)

    target = y_train[target_i]  # (B)
    neighbors = y_train[neighbor_i]

    target_embeddings = W_target(target)  # (B x d_embed)

    logits = (
        target_embeddings @ W_neighbor.weight.T
    )  # (B x d_embed) @ (d_embed x V) -> (B x V)

    m = logits.max(dim=-1, keepdim=True).values

    log_probs = logits - (
        m + torch.log(torch.sum(torch.exp(logits - m), dim=-1, keepdim=True))
    )  # (B, V)

    log_target_probs = log_probs.gather(1, neighbors)  # (B x N)
    loss = -log_target_probs.mean()

    optimizer.zero_grad()
    loss.backward()
    optimizer.step()

    print(loss.item())

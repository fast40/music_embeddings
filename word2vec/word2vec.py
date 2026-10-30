import re
from collections import Counter

import torch
from torch import nn, optim
import numpy as np
from tqdm import tqdm

torch.manual_seed(1337)

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(device)

with open("bible_clean.txt", "r") as file:
    text = file.read()

text = re.sub(r"[^A-Za-z\s]", "", text)
text = text.upper()
words = text.split()

counter = Counter(words)
vocab = [word for word, _ in counter.most_common()]
stoi = {word: i for i, word in enumerate(vocab)}

y_train = torch.tensor([stoi[word] for word in words], device=device)

vocab_size = len(vocab)
d_embed = 128
n_words_to_left_and_right = 5
batch_size = 2**14
n_batches = 2**12
initial_lr = 1e-1

W_target = nn.Embedding(vocab_size, d_embed, device=device)
W_neighbor = nn.Embedding(vocab_size, d_embed, device=device)

optimizer = optim.Adam([*W_target.parameters(), *W_neighbor.parameters()], lr=1e-2)

try:
    for i in tqdm(range(n_batches)):
        learning_rate = initial_lr * np.cos(torch.pi / 2 * i / n_batches)
        optimizer.param_groups[0]["lr"] = learning_rate

        min_index = n_words_to_left_and_right
        max_index = len(y_train) - n_words_to_left_and_right

        target_i = torch.randint(min_index, max_index, (batch_size,), device=device)

        offsets = torch.cat(
            [
                torch.arange(-n_words_to_left_and_right, 0, device=device),
                torch.arange(1, n_words_to_left_and_right + 1, device=device),
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

        # print(
        #     f"loss: {loss.item()}  learning_rate: {learning_rate}  i: {i}/{n_batches}"
        # )
finally:
    torch.save(W_target, "embeddings.pt")

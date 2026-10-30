with open("bible.txt", "r") as file:
    for line in file:
        print(line.split("\t")[-1], end="")

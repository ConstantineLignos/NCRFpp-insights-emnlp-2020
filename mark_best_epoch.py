from io import StringIO
import os
import sys

import pandas as pd

CHAR_MODELS = {
    "nochar": "None",
    "charlstm": "LSTM",
    "charcnn": "CNN",
}


def main() -> None:
    path = sys.argv[1]
    data = pd.read_csv(path, sep="\t")

    ncrfpp_best = 0.0
    ncrfpp_best_epoch = -1
    seqeval_best = 0.0
    seqeval_best_epoch = -1
    for index, row in data.iterrows():
        ncrfpp_score = row["F1.NCRFpp"]
        seqeval_score = row["F1.seqeval"]
        epoch = row["Epoch"]

        if ncrfpp_score > ncrfpp_best:
            ncrfpp_best = ncrfpp_score
            ncrfpp_best_epoch = epoch

        if seqeval_score > seqeval_best:
            seqeval_best = seqeval_score
            seqeval_best_epoch = epoch

    # Use R-style booleans to set best epoch
    data["Best.NCRFpp"] = "FALSE"
    data["Best.seqeval"] = "FALSE"
    data.loc[data["Epoch"] == ncrfpp_best_epoch, "Best.NCRFpp"] = "TRUE"
    data.loc[data["Epoch"] == seqeval_best_epoch, "Best.seqeval"] = "TRUE"

    # Set run properties
    name = os.path.basename(path)
    name_split = name.split(".")
    # First field is the character level
    data["CharModel"] = CHAR_MODELS[name_split[0]]

    # Can't write directly to sys.stdout due to pandas issue
    buf = StringIO()
    data.to_csv(buf, sep="\t", index=False)
    buf.seek(0)
    try:
        print(buf.read(), end="")
    except BrokenPipeError:
        # It's fine, we're probably piping to something
        pass


if __name__ == '__main__':
    main()

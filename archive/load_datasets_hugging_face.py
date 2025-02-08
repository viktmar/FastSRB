
import os
import yaml
import pandas as pd
from datasets import load_dataset

# misc info # --------------------------------------------------------------------------------------
repo_dataset_order_and_ids = {
        "easy": ["I.12.1", "I.12.4", "I.12.5", "I.14.3", "I.14.4", "I.18.12", "I.18.16",
                 "I.25.13", "I.26.2", "I.27.6", "I.30.5", "I.43.16", "I.47.23",
                 "II.2.42", "II.3.24", "II.4.23", "II.8.31", "II.10.9", "II.13.17",
                 "II.15.4", "II.15.5", "II.27.16", "II.27.18", "II.34.11", "II.34.29b",
                 "II.38.3", "II.38.14", "III.7.38", "III.12.43", "III.15.27"],
        "medium": ["I.8.14", "I.10.7", "I.11.19", "I.12.2", "I.12.11", "I.13.4",
                   "I.13.12", "I.15.10", "I.16.6", "I.18.4", "I.24.6", "I.29.4",
                   "I.32.5", "I.34.8", "I.34.10", "I.34.27", "I.38.12", "I.39.10",
                   "I.39.11", "I.43.31", "I.43.43", "I.48.2", "II.6.11", "II.8.7",
                   "II.11.3", "II.21.32", "II.34.2", "II.34.2a", "II.34.29a", "II.37.1",
                   "III.4.32", "III.8.54", "III.13.18", "III.14.14", "III.15.12",
                   "III.15.14", "III.17.37", "III.19.51", "B8", "B18"],
        "hard": ["I.6.20", "I.6.20a", "I.6.20b", "I.9.18", "I.15.3t", "I.15.3x",
                 "I.29.16", "I.30.3", "I.32.17", "I.34.14", "I.37.4", "I.39.22",
                 "I.40.1", "I.41.16", "I.44.4", "I.50.26", "II.6.15a", "II.6.15b",
                 "II.11.17", "II.11.20", "II.11.27", "II.11.28", "II.13.23", "II.13.34",
                 "II.24.17", "II.35.18", "II.35.21", "II.36.38", "III.4.33", "III.9.52",
                 "III.10.19", "III.21.20", "B1", "B2", "B3", "B4", "B5", "B6", "B7",
                 "B9", "B10", "B11", "B12", "B13", "B14", "B15", "B16", "B17", "B19",
                 "B20"]
}

repo_paths = {
        "easy":   "yoshitomo-matsubara/srsd-feynman_easy",
        "medium": "yoshitomo-matsubara/srsd-feynman_medium",
        "hard":   "yoshitomo-matsubara/srsd-feynman_hard"
}

ds_len = {"train": 8000, "validation": 1000, "test": 1000}

# helper functions # -------------------------------------------------------------------------------
def extract_dataset_by_ds_num(ds_num):
    df_train_valid_test = []
    for partition in ["train", "validation", "test"]:
        i_st = ds_num       * ds_len[partition]
        i_en = (ds_num + 1) * ds_len[partition]
        list_of_strings       = dataset[partition][i_st:i_en]["text"]
        list_of_list_of_float = [[float(pp) for pp in p.split()] for p in list_of_strings]
        df = pd.DataFrame(list_of_list_of_float)
        df_train_valid_test.append(df)
    return df_train_valid_test

# download & save all datasets # -------------------------------------------------------------------
for diff in ["easy", "medium", "hard"]:
    repo_path = repo_paths[diff]
    dataset   = load_dataset(repo_path)

    num_datasets = len(repo_dataset_order_and_ids[diff])

    for ds_num in range(num_datasets):
        ds_name = repo_dataset_order_and_ids[diff][ds_num]

        list_of_dfs = extract_dataset_by_ds_num(ds_num)

        for df, part in zip(list_of_dfs, ("train", "valid", "test")):
            path = os.path.join("resources", ds_name + "_" + part + ".csv")
            df.to_csv(path, header=False, index=False)





# with open('srsd_equation.yaml', 'r') as file:
#     eqs = yaml.safe_load(file)

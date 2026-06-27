# Tripme AI Training Module

This module contains tools and Google Colab scripts to fine-tune an AI model (like Gemma 2 or Llama 3) on the Tripme dataset you've gathered.

## 1. Validate Your Data Locally
Before uploading your dataset to Google Drive, make sure it is valid:

```bash
python dataset_validator.py ../../data/sft_osm_data.jsonl
```

## 2. Setup Google Colab
1. Go to [Google Colab](https://colab.research.google.com/).
2. Click **File -> Upload notebook** and upload the `tripme_ai_finetuning_colab.ipynb` file from this folder.
3. In Colab, go to **Runtime -> Change runtime type** and select **T4 GPU** (or better).
4. Upload your `sft_osm_data.jsonl` file to your Google Drive (e.g., in a folder named `TripmeAI`).

## 3. Run the Notebook
Follow the steps inside the Colab Notebook to:
- Install Unsloth and dependencies.
- Mount your Google Drive.
- Load the dataset.
- Train the model using LoRA.
- Save the final optimized model back to your Google Drive.

## 4. Use the Model
Once trained, the notebook will export a `.gguf` file or save the LoRA adapters. You can load this `.gguf` file locally using tools like `ollama` or Python's `llama-cpp-python` to use inside the Tripme backend!

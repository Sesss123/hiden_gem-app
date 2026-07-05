import logging
logger = logging.getLogger(__name__)

import json
import sys
import os

def validate_jsonl(file_path):
    logger.info(f"🔍 Validating Dataset: {file_path}")
    
    if not os.path.exists(file_path):
        logger.info("❌ Error: File does not exist.")
        return False
        
    valid_lines = 0
    errors = 0
    
    with open(file_path, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            
            try:
                data = json.loads(line)
                
                # Check for standard prompt/response format or messages format
                if "text" in data:
                    valid_lines += 1
                elif "instruction" in data and "output" in data:
                    valid_lines += 1
                elif "messages" in data:
                    valid_lines += 1
                else:
                    logger.info(f"⚠️ Warning (Line {i}): JSON valid, but missing expected SFT keys (text, instruction/output, or messages).")
                    valid_lines += 1 # Technically valid JSON, but maybe wrong schema
                    
            except json.JSONDecodeError as e:
                logger.info(f"❌ Error (Line {i}): Invalid JSON -> {e}")
                errors += 1
                
    logger.info("\n--- Validation Results ---")
    logger.info(f"✅ Valid lines: {valid_lines}")
    logger.info(f"❌ Errors: {errors}")
    
    if errors == 0 and valid_lines > 0:
        logger.info("🎉 Dataset is READY for Google Colab training!")
        return True
    else:
        logger.info("⚠️ Please fix the errors before uploading to Colab.")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        logger.info("Usage: python dataset_validator.py <path_to_jsonl_file>")
        logger.info("Example: python dataset_validator.py ../../data/sft_osm_data.jsonl")
    else:
        validate_jsonl(sys.argv[1])

#!/bin/bash
#@ description: Jupyter executes a notebook with the default Python kernel (nbconvert)
#@ param jupyter = jupyter
#@ modules: ${jupyter}
#@ ntasks: 1
#@ time: 10
#@ tags: lang

# Keep Jupyter's runtime/config files inside the test directory.
export JUPYTER_RUNTIME_DIR=$PWD/.jupyter/runtime JUPYTER_CONFIG_DIR=$PWD/.jupyter/config
# hpctest does not copy *.ipynb files into run directories, so the notebook ships as .json.
cp notebook.json test.ipynb
jupyter nbconvert --to notebook --execute --output executed.ipynb test.ipynb 2> nbconvert.log ||
    { cat nbconvert.log >&2; exit 1; }
python3 -c '
import json
nb = json.load(open("executed.ipynb"))
for cell in nb["cells"]:
    for out in cell.get("outputs", []):
        print("".join(out.get("text", "")) or out.get("data", {}).get("text/plain", ""), end="")
'

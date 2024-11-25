#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_NAME = src
PYTHON_VERSION = 3.10
PYTHON_INTERPRETER = python3

#################################################################################
# COMMANDS                                                                      #
#################################################################################

## Set up python interpreter environment
## create .env file for environment variables
create_environment:
	$(PYTHON_INTERPRETER) -m venv .venv
	
## Install Python Dependencies
requirements:
	$(PYTHON_INTERPRETER) -m pip install -U pip setuptools wheel
	$(PYTHON_INTERPRETER) -m pip install -r requirements.txt
	$(PYTHON_INTERPRETER) -m pip install -e .

## Install Python Dependencies for GPU CUDA 11.8
requirements_gpu_cu118:
	$(PYTHON_INTERPRETER) -m pip install -U pip setuptools wheel
	$(PYTHON_INTERPRETER) -m pip install -r requirements_gpu.txt
	$(PYTHON_INTERPRETER) -m pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
	$(PYTHON_INTERPRETER) -m pip install -e .

## Install Python Dependencies for GPU CUDA 12.1
requirements_gpu_cu121:
	$(PYTHON_INTERPRETER) -m pip install -U pip setuptools wheel
	$(PYTHON_INTERPRETER) -m pip install -r requirements_gpu.txt
	$(PYTHON_INTERPRETER) -m pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
	$(PYTHON_INTERPRETER) -m pip install -e .

## Delete all compiled Python files
clean:
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete

## Run train on mnist dataset
train:
	$(PYTHON_INTERPRETER) $(PROJECT_NAME)/train_model.py hydra.job.chdir=False

## Bulid docker image for training
docker_build_train:
	docker build -f dockerfiles/train_model.dockerfile . -t trainer:latest

## Run docker image for training
docker_run_train:
	docker run --name trainer_experiment trainer:latest
#################################################################################
# PROJECT RULES                                                                 #
#################################################################################

## Process raw data into processed data
download_data:
	dvc pull --force

data: download_data
	python3 $(PROJECT_NAME)/data/make_dataset.py

#################################################################################
# Documentation RULES                                                           #
#################################################################################

## Build documentation
build_documentation: dev_requirements
	mkdocs build --config-file docs/mkdocs.yaml --site-dir build

## Serve documentation
serve_documentation: dev_requirements
	mkdocs serve --config-file docs/mkdocs.yaml

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

#################################################################################
# Coverage                                                                      #
#################################################################################
coverage:
	$(PYTHON_INTERPRETER) -m pip install coverage
	coverage run -m pytest
	coverage report -m
	# upload coverage report to a html file
	coverage html

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available commands:$$(tput sgr0)"
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
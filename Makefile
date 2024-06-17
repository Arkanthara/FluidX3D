# system python interpreter. used only to create virtual environment
PY = python3
VENV = .venv
BIN=$(VENV)/bin
.PHONY = install, clean, jupyter, report, deactivate

# make it work on windows too
ifeq ($(OS), Windows_NT)
    BIN=$(VENV)/Scripts
    PY=python
endif

venv:
	test -d $(VENV) || $(PY) -m venv $(VENV)
	(. $(BIN)/activate;)

install: venv
	$(BIN)/pip install --upgrade pip
	$(BIN)/pip install --upgrade numpy matplotlib pandas

report:
	quarto render Report.qmd

clean:
	rm -rf $(VENV)

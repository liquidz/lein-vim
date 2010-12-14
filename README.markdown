# lein.vim
plugin for leiningen

## Commands
**:LeinPom**
  lein pom

**:LeinInstall**
  lein install

**:LeinJar**
  lein jar

**:LeinTest**
  lein test

  open another buffer for test result
  "q" for closing buffer window

**:LeinDeps**
  lein deps

**:LeinUberJar**
  lein uberjar
  
**:LeinClean**
  lein clean

**:LeinCompile**
  lein compile

**:LeinCompileThis**
  lein compile [*ns*]

**:LeinRun**
  lein run -m [*ns*]

  open another buffer for run result
  "q" for closing buffer window

**:Lein <args>**
  lein <args>

## Key maps
### normal mode
**`<Leader>`lm**
  :LeinPom
  
**`<Leader>`li**
  :LeinInstall

**`<Leader>`lj**
  :LeinJar

**`<Leader>`lt**
  :LeinTest

**`<Leader>`ld**
  :LeinDeps

**`<Leader>`lc**
  :LeinCompile

**`<Leader>`lC**
  :LeinCompileThis

**`<Leader>`lr**
  :LeinRun

**`<Leader>`ll**
  :Lein

### insert mode
**`<Leader>`ns**
  expand to *ns*

### command mode
**`<Leader>`ns**
  expand to *ns*

#!/bin/bash -v

fpc -version

fpc -Mdelphi -CX -O3 -XX -vewnhi -Fi. -Fu. -FU. islands.lpr

fpc -Mdelphi -CX -O3 -XX -vewnhi -Fi. -Fu. -FU. islands2.lpr




####### Own example
library(NMdata)
library(NMsim)
library(devtools)
load_all("~/wdirs/recycle")

## Get the setup ready for NMsim
path.candidates <- c(## metworx
    "/opt/NONMEM/nm75/run/nmfe75"
    ## custom linux
   ,"/opt/nonmem/nm760/run/nmfe76"
   ,"/opt/nonmem/nm751/run/nmfe75"
    ## Ahmed
   ,"c:/nm75g64/run/nmfe75.bat"
)
NMdataConf(path.nonmem = NMsim:::prioritizePaths(path.candidates)) ## path to whichever NONM

dir.res <- "~/wdirs/NMsim/devel/needRun/res"
NMdataConf(dir.sims="~/wdirs/NMsim/devel/needRun/tmp")
NMdataConf(dir.res=dir.res)
# First run - executes simulation

## Point to the model to estimate
file.mod <- "~/wdirs/NMsim/inst/examples/nonmem/xgxr021.mod"
## Easily create a muliple-dose simulation data set with a loading dose
data.sim <- NMcreateDoses(TIME=c(0,24),AMT=c(300,150),ADDL=5,II=24,CMT=1)|>
  NMaddSamples(TIME=0:(24*7),CMT=2)
## Simulate
## simres <- NMsim(file.mod=file.mod,data=data.sim,table.vars=c("PRED","IPRED","Y"))

res0 <- NMsim(file.mod=file.mod,data=data.sim,table.vars=c("PRED","IPRED","Y"))

res0 <- NMreadSim("~/wdirs/NMsim/devel/needRun/res/xgxr021_noname_MetaData.rds")
## todo arg path.res -> file.res
file.res <- file.path(dir.res,"xgxr021_noname_MetaData.rds")
res0 <- NMreadSim(file.res)

## unlink(file.res)

res1 <- recycle(NMsim,
                  args=list(file.mod=file.mod,
                            data=data.sim,
                            table.vars=c("PRED","IPRED","Y")),
                  path.res = file.res,
                fun.read=NMreadSim,
                save.res=FALSE
                ## force=T
                )


## readRDS(file.res)


res1 <- recycle(NMsim,
                  args=list(file.mod=file.mod,
                            data=data.sim,
                            table.vars=c("PRED","IPRED","Y")),
                  path.res = file.res,
                fun.read=NMreadSim,
                save.res=FALSE
                ## force=T
                )

library(tools)
file.res
md5sum(file.res)
file.digests <- fnAppend(file.res,"digests")
readRDS(file.digests)
## unlink(file.digests)

### using tailored argument unwrapping

res1 <- recycle(NMsim,
                  args=list(file.mod=file.mod,
                            data=data.sim,
                            table.vars=c("PRED","IPRED","Y")),
                  path.res = file.res,
                fun.read=NMreadSim,
                args.unwrap=list(file.mod=function(x)readLines(x,warn=FALSE),
                                 noexist=stop),
                save.res=FALSE,
                ## force=T
                )

readRDS(fnAppend(file.res,"digests"))




# jotego cores ZXTRES ports

Instructions to compile cores for ZXtres ports of Jotego cores.  

**Prerequisites**

- Ubuntu 20.04
- Install Quartus 17 or higher  in /opt/intelFPGA_lite
- Install Vivado 2022.1 or higher
- Run the jotego_20.04.sh script to get other required packages in place  [https://github.com/jotego/jtcores/blob/master/modules/jtframe/doc/compilation.md](https://github.com/jotego/jtcores/blob/master/modules/jtframe/doc/compilation.md)



```sh
#First time
git clone --recursive https://github.com/somhi/jtcores
cd jtcores
git checkout zxtres
source setprj.sh
cd $JTFRAME/cc && make && cd -
#run script for each core (outrun, gng, ...) and target board (-zx3a200, -zx3a100, -zx3a35):
jtcore2 outrun -zx3a200 -d JTFRAME_RELEASE
jtcore2 outrun -zx3a100 --nodbg
jtcore2 outrun -zx3a35 --nodbg

#Successive times
source setprj.sh
jtcore2 core_folder_name -zx3axxx --nodbg
```



**Old procedure**

```sh
source setprj.sh
# generate "fake" Quartus project for zxtres board
jtcore2 pang -zx3a200 --nodbg
cd ../../cores/pang/zxtres
rm -r db output_files
cp ../../../modules/jtframe/target/zxtres/moyone/* .
#./generate_vivado_project.sh  includes all below
python3 qpf_to_xpr.py
#fix if needed any errors of qsf or qip files including spaces before file locatio
source /opt/Xilinx/Vivado/2022.2/settings64.sh 
vivado -mode tcl -source generar_proyecto_vivado.tcl
```


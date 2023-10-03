# jotego cores ZXTRES ports



```sh
source setprj.sh
jtcore2 outrun -zx3a200 -d JTFRAME_RELEASE
jtcore2 outrun -zx3a100 --nodbg
jtcore2 outrun -zx3a35 --nodbg
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


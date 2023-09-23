# jotego cores - zxtres ports

```sh
source setprj.sh
jtcore2 cps1 -zxtres -d JTFRAME_RELEASE
cd ../../cores/cps1/zxtres
rm -r db output_files
cp ../../../modules/jtframe/target/zxtres/moyone/* .
#edit qpf_to_xpr.py and change qsf filename 
./generate_vivado_project.sh
```



- generate "fake" Quartus project for zxtres board

  ```
  jtcore2 kicker -zxtres -d JTFRAME_RELEASE
  ```

- copy inside zxtres folder: qpf_to_xpr.py, generate_vivado_project.sh and latest zxtres.xdc

  ```
  cp ../../../modules/jtframe/target/zxtres/moyone/* .
  ```

- Edit qpf_to_xpr.py and change qsf filename 

- ```sh
  ./generate_vivado_project.sh
  #python3 qpf_to_xpr.py
  #fix if needed any errors of qsf or qip files including spaces before file locatio
  ```


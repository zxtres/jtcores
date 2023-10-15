#!/usr/bin/env python3

# SCRIPT TO CONVERT QUARTUS PROJECT FILE (QSF) INTO VIVADO PROJECT (XPR)
# Copyright © 2023 by Jose Manuel (@moyone)

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# 03/10/23 modified by @somhi

import os
import re
import getopt,sys
from datetime import datetime

# Obtengo directorio actual
current_dir = os.getcwd()

# Obtengo ficheros en el directorio
files = os.listdir(current_dir)

# Fichero por defecto en caso de no localizar uno en el directorio
input_file = "jtkicker.qsf"

# Localizar primer archivo .QSF
for file in files:
    if file.endswith(".qsf"):
        input_file = file
        break

output_file = "generar_proyecto_vivado.tcl"

# Opciones/Parámetros
create_A35T = 0
create_A100T = 0
create_A200T = 0
change_v_to_vs = 1
run = 1

if (len(sys.argv) > 1):
    argumentList = sys.argv[1:]

    # Opciones cortas 1 = A100T, 2 = A200T, 3 = A35T
    options = "123nx"

    # Opciones largas A100T, A200T, A35T
    long_options = ["A100T", "A200T", "A35T", "no_v_to_sv", "norun"]

    try:
        # Parsing
        arguments, values = getopt.getopt(argumentList, options, long_options)
        
        # Localizando opciones indicadas por línea de comandos
        for currentArgument, currentValue in arguments:
            if currentArgument in ("-1", "--A100T"):
                create_A100T = 1
                print("Se procesará Core para A100T")
            elif currentArgument in ("-2", "--A200T"):
                create_A200T = 1
                print("Se procesará Core para A200T")
            elif currentArgument in ("-3", "--A35T"):
                create_A35T = 1
                print("Se procesará Core para A35T")
            elif currentArgument in ("-v", "--no_v_to_sv"):
                change_v_to_vs = 0
                print("No se cambiará el tipo a SVerilog para los ficheros verilog")
            elif currentArgument in ("-x", "--norun"):
                run = 0
                print("No se crearán las líneas de ejecución de los Design Runs en el TCL")
        if (create_A35T == 0 and create_A100T == 0 and create_A200T == 0):
            create_A35T = 1
            create_A100T = 1
            create_A200T = 1
            print("No se especificó FPGA, se crearán las tres.")

            
    except getopt.error as err:
        print(str(err))
else:
    create_A100T = 1
    create_A200T = 1
    create_A35T = 1
    change_v_to_vs = 1
    print("No se especificó FPGA, se crearán las tres.")

def extract_file_paths(file_path, base_path=None):
    if base_path is None:
        base_path = os.path.dirname(os.path.abspath(file_path))
    try:
        file_paths = []
        with open(file_path, 'r') as f:
            print(f"Procesando fichero: {file_path}")
            content = f.readlines()

        # Buscamos rutas de archivos con los tipos VHDL_FILE, VERILOG_FILE, SYSTEMVERILOG_FILE, SDC_FILE y QIP_FILE
        pattern = r'set_global_assignment\s+-name\s+(VHDL_FILE|VERILOG_FILE|QIP_FILE|SYSTEMVERILOG_FILE)\s+(.*?)$'
        # pattern = r'set_global_assignment\s+-name\s+(VHDL_FILE|VERILOG_FILE|QIP_FILE|SYSTEMVERILOG_FILE|SDC_FILE)\s+(.*?)$'
        for line in content:
            line = line.replace("file join $::quartus(qip_path) ", "").strip()
            match = re.match(pattern, line)
            if match:
                keyword, path = match.groups()
                path = path.strip('"[]').strip()

                # Si la ruta comienza con "file join", extraemos los argumentos y construimos la ruta
                if path.startswith("file join"):
                    tcl_args = re.findall(r'\{.*?\}|\S+', path[len("file join"):])
                    evaluated_args = [arg.strip("{}") if arg.startswith('{') else arg for arg in tcl_args]
                    path = os.path.normpath(os.path.join(*evaluated_args))

                file_path = normalize_path(path, base_path)

                # Si la ruta es un archivo .qip, lo procesamos recursivamente con el nuevo base_path
                if file_path.endswith(".qip"):
                    qip_file_path = normalize_path(file_path, base_path)
                    nested_file_paths = extract_file_paths(qip_file_path, os.path.dirname(file_path))
                    file_paths.extend(nested_file_paths)
                else:
                    # XDC y SDC a "constr_1" el resto a "sources_1"
                    if (file_path.strip()[-2:]=='dc'):
                        container = "constrs_1"
                    else:
                        container = "sources_1"
                    if (" " in file_path.strip()):
                        # Agregamos el tipo SVerilog a los ficheros .v para redudir el numero de alertas de Vivado
                        file_paths.append(f'add_files -fileset {container} {{\"{file_path.strip()}\"}}')
                        if (file_path.strip()[-2:]=='.v'  and change_v_to_vs == 1):
                            file_paths.append(f'set_property file_type SystemVerilog [get_files  {{\"{file_path.strip()}\"}}]')
                    else:
                        # Agregamos el tipo SVerilog a los ficheros .v para redudir el numero de alertas de Vivado
                        file_paths.append(f'add_files -fileset {container} {{{file_path.strip()}}}')
                        if (file_path.strip()[-2:]=='.v'  and change_v_to_vs == 1):
                            file_paths.append(f'set_property file_type SystemVerilog [get_files  {{{file_path.strip()}}}]')
    except:
        print(f"Warning: No se encontró el fichero {file_path}")
        
    return file_paths

def normalize_path(path, base_path):
    # Convertimos las rutas a rutas relativas si no son absolutas
    if not os.path.isabs(path):
        path = os.path.normpath(os.path.join(base_path, path)).replace("\\", "/")
    return path

def write_file_paths_to_output(file_paths, output_path, target_fpga):
    with open(output_path, 'w') as f:
        f.write(f'# Create the project and directory structure\ncreate_project -force zxtres ./ -part {target_fpga}\n#\n# Add sources to the project\n')
        for path in file_paths:
            f.write(f"{path}\n")

def crear_defs_vh():
    with open('./defs.vh', 'w') as f_defs:
    #    f_defs.write('`define VIVADO\n')
        with open(input_file, 'r') as f_input:
            content = f_input.readlines()

            # Buscamos macros VERILOG_MACRO en el QSF
            file_paths = []
            pattern = r'set_global_assignment\s+-name\s+VERILOG_MACRO\s+"([^"]+)"$'
            for line in content:
                line = line.strip()
                match = re.match(pattern, line)
                if match:
                    macro = match.group(1)
                    f_defs.write(f"`define {macro.replace('=', ' ')}\n")
    
def crear_build_id_vh():
    fechahora = datetime.now()
    with open('./build_id.vh', 'w') as f:
        f.write(f"`define BUILD_DATE \"{fechahora.strftime('%y%m%d')}\"\n`define BUILD_TIME \"{fechahora.strftime('%H%M%S')}\"\n")

def main():
    
    if (create_A200T == 1):
        # ZXTRES ++
        target_fpga = 'xc7a200tfbg484-2'  
    elif (create_A35T == 1):
        # ZXTRES
        target_fpga = 'xc7a35tfgg484-2' 
    elif (create_A100T == 1):
        # ZXTRES +
        target_fpga = 'xc7a100tfgg484-2'
    
    file_paths = extract_file_paths(input_file)

    file_paths.append('add_files -fileset sources_1 {./defs.vh}')
    file_paths.append('add_files -fileset sources_1 {./build_id.vh}')
    file_paths.append('add_files -fileset constrs_1 {./zxtres.xdc}')

    file_paths.append('set_property IS_GLOBAL_INCLUDE true [get_files ./defs.vh]')
    file_paths.append('set_property IS_GLOBAL_INCLUDE true [get_files ./build_id.vh]')

    if file_paths:
        # Agregar todos los ficheros del proyecto al script TCL
        write_file_paths_to_output(file_paths, output_file, target_fpga)
        print(f"\nSe han extraído {len(file_paths)} rutas de archivos y se han guardado en el script '{output_file}'.")
    else:
        print("\nNo se encontraron rutas de archivos en el archivo de entrada.")

    
    with open(output_file, 'a') as f:
        # Instrucciones para establecer el TOP MODULE
        f.write(f"set_property top jtframe_zxtres_top [current_fileset]\n")
#        f.write(f"set_property top_file {./jtframe_zxtres_top} [current_fileset]\n")

        # Instrucción para establecer los directorios de búsqueda para ficheros de inclusión
        f.write(f"set_property -name \"include_dirs\" -value \"[file normalize \"../../../modules/jtframe/hdl/inc\"] [file normalize \"../hdl\"]\" -objects [current_fileset]\n")

        #MIST_IO SDC 
        f.write(f"add_files -fileset constrs_1 -norecurse \"../../../modules/jtframe/target/zx3a200/mist_io.sdc\"\n")
        f.write(f"set_property target_constrs_file \"../../../modules/jtframe/target/zx3a200/mist_io.sdc\" [current_fileset -constrset]\n")
        #DP XDC
        f.write(f"add_files -fileset constrs_1 -norecurse \"../../../modules/jtframe/target/zx3a200/plldp/dp.xdc\"\n")

        # Instrucciones para crear el Design Run de la plasca ZXTRES (A35T)
        f.write(f"create_run -name sintesis_A35T -part xc7a35tfgg484-2 -flow {{Vivado Synthesis 2022}} -strategy \"Flow_AreaOptimized_high\" -report_strategy {{Vivado Synthesis Default Reports}} -constrset constrs_1\n")
        f.write(f"create_run -name implementacion_A35T -part xc7a35tfgg484-2 -flow {{Vivado Implementation 2022}} -strategy \"Flow_RunPhysOpt\" -report_strategy {{Vivado Implementation Default Reports}} -constrset constrs_1 -parent_run sintesis_A35T\n")

        # Instrucciones para crear el Design Run de la plasca ZXTRES+ (A100T)
        f.write(f"create_run -name sintesis_A100T -part xc7a100tfgg484-2 -flow {{Vivado Synthesis 2022}} -strategy \"Vivado Synthesis Defaults\" -report_strategy {{Vivado Synthesis Default Reports}} -constrset constrs_1\n")
        f.write(f"create_run -name implementacion_A100T -part xc7a100tfgg484-2 -flow {{Vivado Implementation 2022}} -strategy \"Vivado Implementation Defaults\" -report_strategy {{Vivado Implementation Default Reports}} -constrset constrs_1 -parent_run sintesis_A100T\n")

        # Instrucciones para crear el Design Run de la plasca ZXTRES++ (A200T)
        f.write(f"create_run -name sintesis_A200T -part xc7a200tfbg484-2 -flow {{Vivado Synthesis 2022}} -strategy \"Vivado Synthesis Defaults\" -report_strategy {{Vivado Synthesis Default Reports}} -constrset constrs_1\n")
        f.write(f"create_run -name implementacion_A200T -part xc7a200tfbg484-2 -flow {{Vivado Implementation 2022}} -strategy \"Vivado Implementation Defaults\" -report_strategy {{Vivado Implementation Default Reports}} -constrset constrs_1 -parent_run sintesis_A200T\n")

        # Instrucciones para deshabilitar la síntesis incremental
        f.write(f"set_property -name \"auto_incremental_checkpoint\" -value \"1\" -objects [get_runs sintesis_A200T]\n")
        f.write(f"set_property -name \"steps.synth_design.args.incremental_mode\" -value \"off\" -objects [get_runs sintesis_A200T]\n")
        f.write(f"set_property -name \"auto_incremental_checkpoint\" -value \"1\" -objects [get_runs sintesis_A100T]\n")
        f.write(f"set_property -name \"steps.synth_design.args.incremental_mode\" -value \"off\" -objects [get_runs sintesis_A100T]\n")
        f.write(f"set_property -name \"auto_incremental_checkpoint\" -value \"1\" -objects [get_runs sintesis_A35T]\n")
        f.write(f"set_property -name \"steps.synth_design.args.incremental_mode\" -value \"off\" -objects [get_runs sintesis_A35T]\n")
        
        # Instrucciones para generar el fichero .bin (bit sin cabecera = .zx3)
        f.write(f"set_property -name \"steps.write_bitstream.args.bin_file\" -value \"1\" -objects [get_runs implementacion_A200T]\n")
        f.write(f"set_property -name \"steps.write_bitstream.args.bin_file\" -value \"1\" -objects [get_runs implementacion_A100T]\n")
        f.write(f"set_property -name \"steps.write_bitstream.args.bin_file\" -value \"1\" -objects [get_runs implementacion_A35T]\n")

        # Verbose level
        # f.write(f"set_property -name \"steps.opt_design.args.verbose\" -value \"1\" -objects [get_runs implementacion_A200T]\n")
        # f.write(f"set_property -name \"options.verbose\" -value \"0\" -objects [get_report_configs -of_objects [get_runs implementacion_A200T] implementacion_A200T_place_report_control_sets_0]\n")

        # Cambiar el Design Run Activo
        if (create_A200T == 1):
            f.write("\ncurrent_run [get_runs sintesis_A200T]\n")
        elif (create_A35T == 1):
            f.write("\ncurrent_run [get_runs sintesis_A35T]\n")
        elif (create_A100T == 1):
            f.write("\ncurrent_run [get_runs sintesis_A100T]\n")
        
        # Eliminar los Design Runs por defecto de Vivado
        f.write("delete_runs \"impl_1\"\n")
        f.write("delete_runs \"synth_1\"\n")

        if (create_A200T == 1 and run == 1):
            # Launch A200T runs
            f.write(f"\nreset_run sintesis_A200T\n")
            f.write(f"launch_runs implementacion_A200T -to_step write_bitstream\n")
            f.write(f"\nwait_on_run implementacion_A200T\n")
            f.write(f"\nputs \"Implementation ZXTRES A200T done!\"\n")

        if (create_A100T == 1 and run == 1):
            # Launch A100T runs
            f.write(f"\nreset_run sintesis_A100T\n")
            f.write(f"launch_runs implementacion_A100T -to_step write_bitstream\n")
            f.write(f"\nwait_on_run implementacion_A100T\n")
            f.write(f"\nputs \"Implementation ZXTRES A100T done!\"\n")

        if (create_A35T == 1 and run == 1):
            # Launch A35T runs
            f.write(f"\nreset_run sintesis_A35T\n")
            f.write(f"launch_runs implementacion_A35T -to_step write_bitstream\n")
            f.write(f"\nwait_on_run implementacion_A35T\n")
            f.write(f"\nputs \"Implementation ZXTRES A35T done!\"\n")

        # Salir
        f.write(f"close_project\n")
        f.write(f"\nquit\n")


    crear_defs_vh()
    crear_build_id_vh()
    
    print("\n==========================================================================================")
    print("Agregar al PATH la ruta de los comandos de Vivado (D:\\Xilinx\\Vivado\2022.2\\bin\\)")
    print("Para generar el proyecto ejecutar: vivado -mode tcl -source generar_proyecto_vivado.tcl")
    print("==========================================================================================\n")
    
# Start processing
main()



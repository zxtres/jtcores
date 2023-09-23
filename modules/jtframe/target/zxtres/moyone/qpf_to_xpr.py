import os
import re
from datetime import datetime

def extract_file_paths(file_path, base_path=None):
    if base_path is None:
        base_path = os.path.dirname(os.path.abspath(file_path))

    with open(file_path, 'r') as f:
        content = f.readlines()

    # Buscamos rutas de archivos con los tipos SDC_FILE, VHDL_FILE, VERILOG_FILE y QIP_FILE
    file_paths = []
    #pattern = r'set_global_assignment\s+-name\s+(SDC_FILE|VHDL_FILE|VERILOG_FILE|QIP_FILE|SYSTEMVERILOG_FILE)\s+(.*?)$'
    pattern = r'set_global_assignment\s+-name\s+(VHDL_FILE|VERILOG_FILE|QIP_FILE|SYSTEMVERILOG_FILE)\s+(.*?)$'
    for line in content:
        line = line.replace("file join $::quartus(qip_path) ", "").strip()
        match = re.match(pattern, line)
        if match:
            keyword, path = match.groups()
            path = path.strip('"[]')

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
                if (" " in file_path.strip()):
                    file_paths.append('add_files -fileset sources_1 {"' + file_path.strip().replace(" ", "\\ ") +'"}')
                    # Agregamos el tipo SVerilog a los ficheros .v para redudir el numero de alertas de Vivado
                    if (file_path.strip()[-2:]=='.v'):
                        file_paths.append('set_property file_type SystemVerilog [get_files  \"'+file_path.strip().replace(" ", "\\ ")+'\"]')
                else:
                    # Agregamos el tipo SVerilog a los ficheros .v para redudir el numero de alertas de Vivado
                    file_paths.append('add_files -fileset sources_1 {' + file_path.strip().replace(" ", "\\ ") +'}')
                    if (file_path.strip()[-2:]=='.v'):
                        file_paths.append('set_property file_type SystemVerilog [get_files  \"'+file_path.strip().replace(" ", "\\ ")+'\"]')


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
    with open('./defs.vh', 'w') as f:
        f.write('`define DEMISTIFY\n`define VIVADO\n')
    
def crear_build_id_vh():
    fechahora = datetime.now()
    with open('./build_id.vh', 'w') as f:
        f.write(f"`define BUILD_DATE \"{fechahora.strftime('%y%m%d')}\"\n`define BUILD_TIME \"{fechahora.strftime('%H%M%S')}\"\n")


def main():
    # ZXTRES
    target_fpga = 'xc7a35tfgg484-2' 
    
    # ZXTRES +
    #target_fpga = 'xc7a100tfgg484-2'
    
    # ZXTRES ++
    #target_fpga = 'xc7a200tfbg484-2'
    
    input_file = "jtcps1.qsf"
    
    output_file = "generar_proyecto_vivado.tcl"

    file_paths = extract_file_paths(input_file)

    file_paths.append('add_files -fileset sources_1 {./defs.vh}')
    file_paths.append('add_files -fileset sources_1 {./build_id.vh}')
    file_paths.append('add_files -fileset constrs_1 {./zxtres.xdc}')

    file_paths.append('set_property IS_GLOBAL_INCLUDE true [get_files ./defs.vh]')
    file_paths.append('set_property IS_GLOBAL_INCLUDE true [get_files ./build_id.vh]')

    file_paths.append('set_property -name "top" -value "jtframe_zxtres_top" -objects $obj')
    file_paths.append('set_property -name "top" -value "jtframe_zxtres_top" -objects $obj')
    file_paths.append('set_property -name "include_dirs" -value "[file normalize "$origin_dir/../../../modules/jtframe/hdl/inc"] [file normalize "$origin_dir/../hdl"]" -objects $obj')
    

    if file_paths:
        write_file_paths_to_output(file_paths, output_file, target_fpga)
        print(f"Se han extraído {len(file_paths)} rutas de archivos y se han guardado en '{output_file}'.")
    else:
        print("No se encontraron rutas de archivos en el archivo de entrada.")

    crear_defs_vh()
    crear_build_id_vh()
    
if __name__ == "__main__":
    main()



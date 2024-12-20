import os

def generate_header_file(header_guard, data_type, input_file_path, output_file_path, array_name):
    try:
        # Read the data from the input file
        with open(input_file_path, 'r') as infile:
            data = infile.read().strip().split()
        
        # Convert data to integers (or other processing if needed)
        data = [int(item) for item in data]

        # Get the size of the array
        size = len(data)

#         # Prepare the content for the header file
#         header_content = f"""#ifndef {header_guard}
# #define {header_guard}

# {data_type} {array_name}[{size}] = {{{', '.join(map(str, data))}}};

# #endif /* !{header_guard} */
# """
        header_content = f"""

{data_type} {array_name}[{size}] = {{{', '.join(map(str, data))}}};


"""
        # Write the content to the output file
        with open(output_file_path, 'w') as outfile:
            outfile.write(header_content)

        print(f"Header file created successfully at '{output_file_path}'.")

    except FileNotFoundError:
        print(f"Error: The file '{input_file_path}' does not exist.")
    except ValueError:
        print("Error: Input file contains non-integer values.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")




def main():

    project_root = os.path.abspath(os.path.join(os.getcwd()))

    print("project root", project_root)

    # Set paths and configurations
    header_guard_name = "_HSI_DATA_H"
    data_type_name = "int"
    array_name = "hsi_data"
    input_file_path = os.path.abspath(os.path.join(project_root, "example", "PolyBenchC-4.2.1-brain-HSI", "calibration", "input", "organized_ID0067C02.in"))  # Path to the input file
    # output_file_path = os.path.abspath(os.path.join(project_root, "example", "PolyBenchC-4.2.1-brain-HSI", "calibration", "hsi.data.h"))  # Path to the input file
    output_file_path = os.path.abspath(os.path.join(project_root, "example", "PolyBenchC-4.2.1-brain-HSI", "calibration", "hsi.data.c"))  # Path to the input file


    # Generate the header file
    generate_header_file(header_guard_name, data_type_name, input_file_path, output_file_path, array_name)


if __name__ == "__main__":
    main()



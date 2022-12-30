# ADNS-3080 Sensor Driver with VHDL and SPI

This project contains VHDL code for driving the ADNS-3080 optical sensors using SPI communication. Its aim is to provide a simple and reliable interface for reading the sensors' movement and position data.

## Compilation and Testing

To compile and test the VHDL code, you need:

- A VHDL synthesis tool, such as Xilinx Vivado or Altera Quartus
- An emulator or target hardware compatible with the ADNS-3080 sensor and the SPI bus

Follow these steps:

1. Open the project in your VHDL synthesis tool.
2. Select the desired target hardware or emulator.
3. Compile the code by selecting "Synthetize" or "Compile".
4. Load the code onto the target hardware or emulator.
5. Run the tests by sending SPI commands and verifying that the sensor responses are as expected.

## Using as a Library

To use the VHDL code in this project as a library in another project, follow these steps:

1. Add the project directory as a library directory in your VHDL synthesis tool.
2. Add `use` statements in your code to import the necessary entities and packages.
3. Instantiate the library components in your synthesis schema.
4. Compile and load the code as usual.

## References

- [ADNS-3080 Sensor Documentation](https://github.com/rppouill/ADNS-3080/blob/main/adns_3080.pdf)
- [SPI Communication Protocol](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface)


Tree Structure

├── FPGA 
│   ├── module1.vhd 
│   |	├── Frame_Capture.vhd 
│   └── module3.vhd 
├── README.md 
├── LICENSE 
└── adns_3080.pdf 

.
├── src
│   ├── module1.vhd
│   ├── module2.vhd
│   └── module3.vhd
├── test
│   ├── testbench1.vhd
│   ├── testbench2.vhd
│   └── testbench3.vhd
├── README.md
├── LICENSE
└── .gitignore

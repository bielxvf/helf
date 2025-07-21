use errors;
use fmt;
use fs;
use io;
use os;

export fn main() void = {
	if (len(os::args) < 2) {
		fmt::fprintfln(os::stdout, "Error: [FILE] argument needed.")!;
		print_usage()!;
		os::exit(1);
	} else if (os::args[1] == "-h" || os::args[1] == "--help") {
		print_usage()!;
		return;
	};
	const path = os::args[1];
	const file = match (os::open(path)) {
	case let file: io::file =>
		yield file;
	case let err: fs::error =>
		fmt::fatalf("Error opening '{}': {}", path, fs::strerror(err));
	};
	defer io::close(file)!;

	const file_content = match (io::drain(file)) {
	case let file_content: []u8 =>
		yield file_content;
	case let err: io::error =>
		fmt::fatalf("Error reading '{}': {}", path, io::strerror(err));
	};

	match (is_ELF(file_content)) {
	case void =>
		yield;
	case let err: error =>
		fmt::fatalf("Error: {}", strerror(err));
	};

	const format = match(get_format(file_content)) {
	case let f: str =>
		yield f;
	case let err: error =>
		fmt::fatalf("Error getting format: {}", strerror(err));
	};

	const endianness = match(get_endianness(file_content)) {
	case let e: str =>
		yield e;
	case let err: error =>
		fmt::fatalf("Error getting endianness: {}", strerror(err));
	};

	const elfversion = match(get_version(file_content)) {
	case let v: str =>
		yield v;
	case let err: error =>
		fmt::fatalf("Error getting version: {}", strerror(err));
	};

	fmt::printfln("ELF")!;
	fmt::printfln("Class: {}", format)!;
	fmt::printfln("Endianness: {}", endianness)!;
	fmt::printfln("Version: {}", elfversion)!;
};

fn print_usage() (void | io::error) = {
	fmt::printfln("Usage: helf [OPTIONS...] [FILE]")?;
	fmt::printfln("Options:")?;
	fmt::printfln("\t-h,--help\tPrint this help message")?;
};

fn is_ELF(file_content: []u8) (void | error) = {
	const elfoffset: size = 0x0;
	if (len(file_content) < elfoffset + 1) {
		return invalid_length;
	};

	const ELF_MAGIC_NUMBER: [4]u8 = [0x7f, 0x45, 0x4c, 0x46];

	for (let i: size = elfoffset; i < 4 && i < len(file_content); i += 1) {
		if (file_content[i] != ELF_MAGIC_NUMBER[i]) {
			return not_elf;
		};
	};
};

fn get_format(file_content: []u8) (str | error) = {
	const elfoffset: size = 0x04;
	if (len(file_content) < elfoffset + 1) {
		return invalid_length;
	};
	switch (file_content[elfoffset]) {
	case 1 =>
		return "32-bit (4-byte word)";
	case 2 =>
		return "64-bit (8-byte word)";
	case => {
		return invalid_format;
	};
	};
};

fn get_endianness(file_content: []u8) (str | error) = {
	const elfoffset: size = 0x05;
	if (len(file_content) < elfoffset + 1) {
		return invalid_length;
	};
	switch (file_content[elfoffset]) {
	case 1 =>
		return "Little Endian";
	case 2 =>
		return "Big Endian";
	case => {
		return invalid_endianness;
	};
	};
};

fn get_version(file_content: []u8) (str | error) = {
	const elfoffset: size = 0x06;
	if (len(file_content) < elfoffset + 1) {
		return invalid_length;
	};
	switch (file_content[elfoffset]) {
	case 1 =>
		return "1 (Original)";
	case => {
		return invalid_version;
	};
	};
};

type invalid_length = !void;
type invalid_format = !void;
type invalid_endianness = !void;
type invalid_version = !void;
type not_elf = !void;
type error = !(invalid_length | invalid_format | invalid_endianness | invalid_version | not_elf);

fn strerror(err: error) str = {
	match (err) {
	case not_elf =>
		return "File is not an ELF binary.";
	case invalid_length =>
		return "Invalid header length.";
	case invalid_format =>
		return "Invalid format (e_ident[EI_CLASS]).";
	case invalid_endianness =>
		return "Invalid endianness (e_ident[EI_DATA]).";
	case invalid_version =>
		return "Invalid version (e_ident[EI_VERSION]).";
	};
};

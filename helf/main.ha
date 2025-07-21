use errors;
use fmt;
use fs;
use io;
use os;

export fn main() void = {
	if (len(os::args) < 2) {
		fmt::fprintfln(os::stdout, "Error: [FILE] argument needed.")!;
		print_usage();
		os::exit(1);
	} else if (os::args[1] == "-h" || os::args[1] == "--help") {
		print_usage();
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

	if (!is_elf(file_content[0..4])) {
		fmt::printfln("'{}' is not an ELF binary!", path)!;
		os::exit(1);
	};

	fmt::printfln("ELF")!;
	fmt::printf("Data: ")!;
	if (is_64bit(file_content)) {
		fmt::printfln("64-bit")!;
	} else {
		fmt::printfln("32-bit")!;
	};
};

fn print_usage() void = {
	fmt::printfln("Usage: helf [OPTIONS...] [FILE]")!;
	fmt::printfln("Options:")!;
	fmt::printfln("\t-h,--help\tPrint this help message")!;
};

fn is_elf(file_content: []u8) bool = {

	if (len(file_content) < 4) {
		return false;
	};

	const ELF_MAGIC_NUMBER: [4]u8 = [0x7f, 0x45, 0x4c, 0x46];

	for (let i: size = 0; i < 4 && i < len(file_content); i += 1) {
		if (file_content[i] != ELF_MAGIC_NUMBER[i]) {
			return false;
		};
	};

	return true;
};

fn is_64bit(file_content: []u8) bool = {

	if (len(file_content) < 5) {
		return false;
	};

	switch (file_content[4]) {
	case 1 => {
		return false;
	};
	case 2 => {
		return true;
	};
	case => {
		return false;
	};
	};
};

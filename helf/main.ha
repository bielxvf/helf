use os;
use io;
use fmt;

export fn main() void = {
	const file = os::open(os::args[1])!;
	defer io::close(file)!;
	const file_content = io::drain(file)!;

	if (!is_elf(file_content)) {
		fmt::println("not an ELF")!;
		return;
	};

	if (is_64bit(file_content)) {
		fmt::println("64-bit ELF")!;
	};
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

	// TODO: Handle this as error
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
		// TODO: Handle this as error
		return false;
	};
	};
};

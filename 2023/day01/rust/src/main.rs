use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::env;

fn str_to_vec(str: String) -> Vec<char> {
    let mut v: Vec<char> = vec![];
    for ch in str.chars() {
        v.push(ch);
    }
    return v;
}

fn part_1(input: Vec<String>) -> u32 {
    let mut sum: u32 = 0;
    
    for line in input {
        let chars: Vec<char> = str_to_vec(line);
        let mut first: u32 = 0x30;
        let mut last: u32 = 0x30;
        let mut first_found: bool = false;
        for ch in chars {
            if (ch as u8) < 0x30 || (ch as u8) > 0x39 {
                continue;
            }
            if !first_found {
                first = ch as u32;
                first_found = true;
            }
            last = ch as u32;
        }
        sum += (first - 0x30) * 10;
        sum += last - 0x30;
    }

    return sum;
}

fn check_written_digit(word: &str, len: usize) -> u8 {
    if len < 3 { return 0; }
    if &word[0..=2] == "one" { return 0x31; }
    if &word[0..=2] == "two" { return 0x32; }
    if &word[0..=2] == "six" { return 0x36; }
    if len < 4 { return 0; }
    if &word[0..=3] == "four" { return 0x34; }
    if &word[0..=3] == "five" { return 0x35; }
    if &word[0..=3] == "nine" { return 0x39; }
    if len < 5 { return 0; }
    if &word[0..=4] == "three" { return 0x33; }
    if &word[0..=4] == "seven" { return 0x37; }
    if &word[0..=4] == "eight" { return 0x38; }
    return 0;
}

fn part_2(input: Vec<String>) -> u32 {
    let mut sum: u32 = 0;
    
    for line in input {
        let chars: Vec<char> = str_to_vec(line.clone());
        let mut first: u32 = 0x30;
        let mut last: u32 = 0x30;
        let mut first_found: bool = false;
        for idx in 0..chars.len() {
            let mut ch: u8 = chars[idx] as u8;
            if (ch as u8) < 0x30 || (ch as u8) > 0x39 {
                ch = check_written_digit(&line[idx..chars.len()], chars.len() - idx);
                if ch == 0 {
                    continue;
                }
            }
            if !first_found {
                first = ch as u32;
                first_found = true;
            }
            last = ch as u32;
        }
        sum += (first - 0x30) * 10;
        sum += last - 0x30;
    }

    return sum;
}

fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    return Ok(io::BufReader::new(file).lines());
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("Usage: <prog> <filename>");
        return;
    }
    let filename: &str = &args[1];
    if let Ok(lines) = read_lines(filename) {
        let mut input: Vec<String> = vec![];
        for line in lines {
            if let Ok(e) = line {
                input.push(e);
            }
        }

        println!("Part 1: {}", part_1(input.clone()));
        println!("Part 2: {}", part_2(input));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn part_1_test() {
        if let Ok(lines) = read_lines("../test.txt") {
            let mut input: Vec<String> = vec![];
            for line in lines {
                if let Ok(e) = line {
                    input.push(e);
                }
            }
            let res = part_1(input);
            assert_eq!(142, res);
        }
    }
    #[test]
    fn part_2_test() {
        if let Ok(lines) = read_lines("../test_2.txt") {
            let mut input: Vec<String> = vec![];
            for line in lines {
                if let Ok(e) = line {
                    input.push(e);
                }
            }
            let res = part_2(input);
            assert_eq!(281, res);
        }
    }
}

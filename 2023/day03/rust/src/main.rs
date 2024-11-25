use std::collections::HashMap;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::env;
use regex::Regex;
use std::cmp::min;

fn part_1(input: Vec<String>) -> u32 {
    let mut sum: u32 = 0;
    let regex = Regex::new(r"\d+").unwrap();

    for i in 0..input.len() {
        let line = &input[i];

        'numbers: for number in regex.find_iter(line) {
            // check previous line
            if i > 0 {
                let prev = &input[i - 1].as_bytes();
                for j in number.start().saturating_sub(1)..min(prev.len(), number.end() + 1) {
                    if prev[j] != b'.' && !prev[j].is_ascii_digit() {
                        sum += number.as_str().parse::<u32>().unwrap();
                        continue 'numbers;
                    }
                }
            }

            // check next line
            if i < input.len() - 1 {
                let next = &input[i + 1].as_bytes();
                for j in number.start().saturating_sub(1)..min(next.len(), number.end() + 1) {
                    if next[j] != b'.' && !next[j].is_ascii_digit() {
                        sum += number.as_str().parse::<u32>().unwrap();
                        continue 'numbers;
                    }
                }
            }

            // check same line
            if number.start() > 0 {
                let left = line.as_bytes()[number.start() - 1];
                if left != b'.' && !left.is_ascii_digit() {
                    sum += number.as_str().parse::<u32>().unwrap();
                    continue 'numbers;
                }
            }

            if number.end() < input.len() {
                let right = line.as_bytes()[number.end()];
                if right != b'.' && !right.is_ascii_digit() {
                    sum += number.as_str().parse::<u32>().unwrap();
                    continue 'numbers;
                }
            }
        }
    }

    return sum;
}

fn part_2(input: Vec<String>) -> u32 {
    let mut sum: u32 = 0;
    let regex = Regex::new(r"\d+").unwrap();
    let mut gears: HashMap<(usize, usize), Vec<u32>> = HashMap::new();
    
    for i in 0..input.len() {
        let line = &input[i];
        
        for number in regex.find_iter(line) {
            // check previous line
            if i > 0 {
                let prev = &input[i - 1].as_bytes();
                for j in number.start().saturating_sub(1)..min(prev.len(), number.end() + 1) {
                    if prev[j] == b'*' {
                        gears.entry((i - 1, j)).or_default().push(number.as_str().parse::<u32>().unwrap());
                    }
                }
            }

            // check next line
            if i < input.len() - 1 {
                let next = &input[i + 1].as_bytes();
                for j in number.start().saturating_sub(1)..min(next.len(), number.end() + 1) {
                    if next[j] == b'*' {
                        gears.entry((i + 1, j)).or_default().push(number.as_str().parse::<u32>().unwrap());
                    }
                }
            }

            // check same line
            if number.start() > 0 {
                let left = line.as_bytes()[number.start() - 1];

                if left == b'*' {
                    gears.entry((i, number.start() - 1)).or_default().push(number.as_str().parse::<u32>().unwrap());
                }
            }
            if number.end() < line.len() {
                let right = line.as_bytes()[number.end()];

                if right == b'*' {
                    gears.entry((i, number.end())).or_default().push(number.as_str().parse::<u32>().unwrap());
                }
            }
        }
    }

    gears.values().filter(|vec| vec.len() == 2).for_each(|vec| sum += vec[0] * vec[1]);

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
            assert_eq!(4361, res);
        }
    }
    #[test]
    fn part_2_test() {
        if let Ok(lines) = read_lines("../test.txt") {
            let mut input: Vec<String> = vec![];
            for line in lines {
                if let Ok(e) = line {
                    input.push(e);
                }
            }
            let res = part_2(input);
            assert_eq!(467835, res);
        }
    }
}

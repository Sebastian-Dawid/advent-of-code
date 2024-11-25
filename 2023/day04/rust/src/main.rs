use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::env;
use itertools::Itertools;

fn part_1(input: Vec<String>) -> u32 {
    let mut sum: u32 = 0;
    
    for line in input {
        let mut winners: u32 = 0;
        let (winning, given) = line.split(": ").nth(1).unwrap()
            .split("|").into_iter().map(|e: &str| e.trim().split(" ").flat_map(str::parse::<u32>).collect())
            .collect_tuple::<(Vec<u32>, Vec<u32>)>().unwrap();

        for num in &given {
            for winner in &winning {
                if num == winner {
                    winners += 1;
                    break;
                }
            }
        }

        if winners > 0 {
            sum += (2 as u32).pow(winners - 1);
        }
    }

    return sum;
}

fn part_2(input: Vec<String>) -> u32 {
    let mut repetitions: Vec<u32> = vec![];
    let mut scratchcard: usize = 0;

    for line in input {
        if repetitions.len()  <= scratchcard {
            repetitions.push(1);
        } else {
            repetitions[scratchcard] += 1;
        }

        let mut winners: u32 = 0;
        let (winning, given) = line.split(": ").nth(1).unwrap()
            .split("|").into_iter().map(|e: &str| e.trim().split(" ").flat_map(str::parse::<u32>).collect())
            .collect_tuple::<(Vec<u32>, Vec<u32>)>().unwrap();

        for num in &given {
            for winner in &winning {
                if num == winner {
                    winners += 1;
                    break;
                }
            }
        }
        
        for _ in 0..repetitions[scratchcard] {
            for j in 1..=winners {
                if repetitions.len() <= scratchcard + j as usize {
                    repetitions.push(1);
                } else {
                    repetitions[scratchcard + j as usize] += 1;
                }
            }
        }

        scratchcard += 1;
    }

    return repetitions.into_iter().fold(0, |acc, x| acc + x );
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
            assert_eq!(13, res);
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
            assert_eq!(30, res);
        }
    }
}

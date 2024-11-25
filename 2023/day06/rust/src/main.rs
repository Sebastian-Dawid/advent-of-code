use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::env;
use std::str;

fn find_num_greater(t: usize, d: usize) -> usize {
    let mut num: usize = 0;
    for i in 1..t {
        if i * (t - i) > d { num += 1; }
    }
    return num;
}

fn part_1(input: Vec<String>) -> usize {
    let mut prod: usize = 1;
 
    let times: Vec<usize> = input[0].split(":").nth(1).into_iter().map(|e| e.trim().split(" ").flat_map(str::parse::<usize>).collect()).nth(0).unwrap();
    let dists: Vec<usize> = input[1].split(":").nth(1).into_iter().map(|e| e.trim().split(" ").flat_map(str::parse::<usize>).collect()).nth(0).unwrap();

    for i in 0..times.len() {
        prod *= find_num_greater(times[i], dists[i]);
    }

    return prod;
}

fn part_2(input: Vec<String>) -> usize {
    let time: usize  = str::from_utf8(&input[0].as_bytes().iter().filter(|x| x.is_ascii_digit()).map(|e| *e).collect::<Vec<u8>>()).unwrap().parse::<usize>().unwrap();
    let dist: usize  = str::from_utf8(&input[1].as_bytes().iter().filter(|x| x.is_ascii_digit()).map(|e| *e).collect::<Vec<u8>>()).unwrap().parse::<usize>().unwrap();
    return find_num_greater(time, dist);
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
            assert_eq!(288, res);
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
            assert_eq!(71503, res);
        }
    }
}

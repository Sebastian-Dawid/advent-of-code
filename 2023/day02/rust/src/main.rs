use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::env;

fn part_1(input: Vec<String>) -> u32 {
    let mut sum: u32 = 0;
    
    let mut id: u32 = 1;
    for line in input {
        let items: Vec<(u32, &str)> = line.split(": ").nth(1).unwrap()
            .split("; ").collect::<Vec<&str>>().iter()
            .map(|e| {e.split(", ")}).flatten().collect::<Vec<&str>>().iter()
            .map(|e| {
                let split = e.split(" ").collect::<Vec<&str>>();
                (split[0].parse::<u32>().unwrap(), split[1])
            }).collect();
        let mut possible = true;
        for item in items {
            match item {
                (i, "red") => if i > 12 { possible = false; },
                (i, "green") => if i > 13 { possible = false; },
                (i, "blue") => if i > 14 { possible = false; },
                _ => ()
            }
        }
        if possible { sum += id; }
        id += 1;
    }

    return sum;
}

fn part_2(input: Vec<String>) -> u32 {
    let mut sum: u32 = 0;
    
    for line in input {
        let items: Vec<(u32, &str)> = line.split(": ").nth(1).unwrap()
            .split("; ").collect::<Vec<&str>>().iter()
            .map(|e| {e.split(", ")}).flatten().collect::<Vec<&str>>().iter()
            .map(|e| {
                let split = e.split(" ").collect::<Vec<&str>>();
                (split[0].parse::<u32>().unwrap(), split[1])
            }).collect();
        let mut max_red = 0;
        let mut max_green = 0;
        let mut max_blue = 0;
        for item in items {
            match item {
                (i, "red") => if i > max_red { max_red = i; },
                (i, "green") => if i > max_green { max_green = i; },
                (i, "blue") => if i > max_blue { max_blue = i; },
                _ => (),
            }
        }
        sum += max_red * max_green * max_blue;
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
            assert_eq!(8, res);
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
            assert_eq!(2286, res);
        }
    }
}

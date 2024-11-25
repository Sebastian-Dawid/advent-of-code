use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::{env, usize};

#[derive(Debug)]
struct Mapping {
    dst_start: usize,
    src_start: usize,
    length: usize
}

impl Mapping {
    fn in_src_range(&self, value: usize) -> bool {
        return self.src_start <= value && value < self.src_start + self.length
    }
    fn in_dst_range(&self, value: usize) -> bool {
        return self.dst_start <= value && value < self.dst_start + self.length
    }
}

type Table = Vec<Mapping>;

fn find_mapped_value(table: &Table, value: usize) -> usize {
    for i in 0..table.len() {
        if table[i].in_src_range(value) {
            return table[i].dst_start + (value - table[i].src_start);
        }
    }
    return value;
}

fn find_unmapped_value(table: &Table, value: usize) -> usize {
    for i in 0..table.len() {
        if table[i].in_dst_range(value) {
            return table[i].src_start + (value - table[i].dst_start);
        }
    }
    return value;
}

fn is_valid_seed(seeds: Vec<usize>, value: usize) -> bool {
    let mut idx: usize = 0;
    while idx < seeds.len() {
        if seeds[idx] <= value && value < seeds[idx] + seeds[idx + 1] {
            return true;
        }
        idx += 2;
    }
    return false;
}

fn generate_tables(input: Vec<String>) -> (Vec<usize>, Vec<Table>) {
    let seeds = input[0].split(": ").nth(1).unwrap().split(" ").flat_map(str::parse::<usize>).collect();
    let mut tables: Vec<Table> = vec![];

    for line in input[2..].iter() {
        if line.len() < 2 { continue; }
        if &line[(line.len() - 4)..(line.len() - 1)] == "map" {
            tables.push(vec![]);
            continue;
        }
        if tables.len() == 0 { continue; }

        let nums: Vec<usize> = line.split(" ").flat_map(str::parse::<usize>).collect();
        let idx = tables.len() - 1;
        tables[idx].push(Mapping{ dst_start: nums[0], src_start: nums[1], length: nums[2] });
    }

    return (seeds, tables);
}

fn part_1(seeds: &Vec<usize>, tables: &Vec<Table>) -> usize {
    let mut min: usize = !0;
    
    for seed in seeds {
        let mut val: usize = *seed;
        for table in tables {
            val = find_mapped_value(table, val);
        }
        min = if val < min { val } else { min };
    }

    return min;
}

fn part_2(seeds: &Vec<usize>, tables: &Vec<Table>) -> usize {
    let mut location: usize = 0;
    let mut seed: usize = 0;

    for table in tables.iter().rev() {
        seed = find_unmapped_value(table, seed);
    }

    while !is_valid_seed(seeds.to_vec(), seed) {
        seed = location;
        for table in tables.iter().rev() {
            seed = find_unmapped_value(table, seed);
        }
        location += 1;
    }

    return location - 1;
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

        let (seeds, tables) = generate_tables(input);

        println!("Part 1: {}", part_1(&seeds, &tables));
        println!("Part 2: {}", part_2(&seeds, &tables));
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
            let (seeds, tables) = generate_tables(input);
            let res = part_1(&seeds, &tables);
            assert_eq!(35, res);
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
            let (seeds, tables) = generate_tables(input);
            let res = part_2(&seeds, &tables);
            assert_eq!(46, res);
        }
    }
}

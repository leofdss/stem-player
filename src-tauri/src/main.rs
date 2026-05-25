// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use stem_core::add;

fn main() {
    let result = add(2, 2);
    println!("{}", result);
    stem_player_lib::run()
}

#[derive(Debug, Hash, Clone, Copy)]
struct GameState {
    moves: [u8; 9],
    squares: [i8; 9],
}

fn mcts(state: GameState) -> u8 {
    0
}

#[rustler::nif]
fn move2idx(mv: (i64, i64)) -> u8 {
    let m0 = mv.0 as u8;
    let m1 = mv.1 as u8;
    let (a, b) = if m0 < m1 { (m0, m1) } else { (m1, m0) };

    10 * a + b
}

#[rustler::nif]
fn idx2move(idx: u8) -> (i64, i64) {
    let a = idx / 10;
    let b = idx - a*10;

    (a as i64, b as i64)
}

#[rustler::nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif]
fn len(a: Vec<i64>) -> usize {
    println!("vector in rust: {:?}", a);
    a.len()
}

#[rustler::nif]
fn ai_move(moves: Vec<(i64, i64)>, squares: Vec<i64>) -> (i64, i64) {
    println!("moves in rust: {:?}", moves);
    println!("squares in rust: {:?}", squares);
    (0, 0)
}

rustler::init!("Elixir.Qttt.Rust", [add, len, ai_move, move2idx, idx2move]);

use rodio::{Decoder, OutputStream, Sink};
use std::env;
use std::fs::File;
use std::io::BufReader;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("Uso: {} <arquivo1.mp3> <arquivo2.mp3>", args[0]);
        std::process::exit(1);
    }

    let arquivo1 = &args[1];
    let arquivo2 = &args[2];

    // Inicializa o dispositivo de saída de áudio padrão (ALSA/PulseAudio/PipeWire).
    // `_stream` precisa permanecer vivo enquanto reproduzimos — se for dropado,
    // o áudio para. Por isso o underscore (não usamos, mas mantemos no escopo).
    let (_stream, stream_handle) =
        OutputStream::try_default().expect("Não foi possível abrir o dispositivo de áudio padrão");

    // Dois sinks independentes que compartilham o mesmo stream de saída.
    // Eles serão mixados automaticamente pelo rodio na thread de áudio.
    let sink1 = Sink::try_new(&stream_handle).expect("Falha ao criar sink 1");
    let sink2 = Sink::try_new(&stream_handle).expect("Falha ao criar sink 2");

    // *** TRUQUE DE SINCRONIZAÇÃO ***
    // Pausamos ANTES de enfileirar as fontes. Assim a decodificação inicial
    // e o setup dos buffers já estão prontos quando dermos play().
    sink1.pause();
    sink2.pause();

    // Decodifica os dois MP3s. BufReader evita I/O síncrono no meio da reprodução.
    let source1 = Decoder::new(BufReader::new(
        File::open(arquivo1).expect("Falha ao abrir arquivo 1"),
    ))
    .expect("Falha ao decodificar arquivo 1 (MP3 inválido?)");

    let source2 = Decoder::new(BufReader::new(
        File::open(arquivo2).expect("Falha ao abrir arquivo 2"),
    ))
    .expect("Falha ao decodificar arquivo 2 (MP3 inválido?)");

    // Enfileira as fontes nos sinks (que continuam pausados).
    sink1.append(source1);
    sink2.append(source2);

    println!(
        "▶  Reproduzindo \"{}\" e \"{}\" simultaneamente...",
        arquivo1, arquivo2
    );

    // Dispara ambos. play() apenas alterna um AtomicBool interno, então o
    // intervalo entre as duas chamadas é da ordem de nanossegundos —
    // muito abaixo de 1 sample de áudio (≈22 µs a 44.1 kHz).
    sink1.play();
    sink2.play();

    // sleep_until_end() bloqueia até o sink ficar vazio. Se o sink já terminou,
    // retorna imediatamente. Portanto, esperando os dois em sequência, o
    // programa só termina quando o áudio MAIS LONGO acabar — não importa
    // qual dos dois seja o maior.
    sink1.sleep_until_end();
    sink2.sleep_until_end();

    println!("✓  Reprodução finalizada.");
}

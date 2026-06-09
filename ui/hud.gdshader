shader_type canvas_item;

// Controla a força da alucinação (de 0.0 a 1.0)
uniform float terror_intensity : hint_range(0.0, 1.0) = 0.0;

// A cor da distorção (configurado por padrão para um Índigo/Violeta profundo)
uniform vec4 base_color : source_color = vec4(0.15, 0.02, 0.30, 1.0);

// Velocidade da pulsação (simulando batimento cardíaco)
uniform float pulse_speed = 4.0;

void fragment() {
    // Centraliza as coordenadas UV
    vec2 center_uv = UV - vec2(0.5);
    
    // Calcula a distância do centro (para fazer o efeito oval/circular nas bordas)
    // Multiplicar o X compensa o aspecto esticado da tela 16:9
    center_uv.x *= 1.7; 
    float dist = length(center_uv);
    
    // Cria um gradiente suave. Quanto maior o terror, mais ele invade o centro.
    float inner_radius = 0.8 - (terror_intensity * 0.5);
    float vignette = smoothstep(inner_radius, inner_radius - 0.4, dist);
    
    // Inverte o gradiente para as bordas ficarem escuras
    vignette = 1.0 - vignette;
    
    // Calcula o batimento cardíaco/pulso baseado no tempo
    float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5) * (terror_intensity * 0.3);
    
    // Aplica a cor violeta e controla a transparência usando o nível de terror + pulsação
    COLOR.rgb = base_color.rgb;
    COLOR.a = vignette * (terror_intensity + pulse);
}
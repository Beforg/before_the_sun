shader_type spatial;
// cull_disabled faz a folha ser desenhada dos dois lados (frente e verso)
// depth_draw_opaque corrige bugs de sombra com texturas transparentes
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap;
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.5;

// Parâmetros do Vento (Ajustáveis no Inspector)
uniform float wind_speed = 1.5;
uniform float wind_strength = 0.05;
uniform float wind_noise = 2.0;

void vertex() {
	// Pega a posição real da árvore no mundo para que cada árvore balance diferente
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Calcula uma onda suave baseada no tempo e na posição espacial
	float sway = sin(TIME * wind_speed + world_pos.x * wind_noise + world_pos.z * wind_noise);
	float shiver = cos(TIME * (wind_speed * 1.5) + world_pos.y * wind_noise);
	
	// Aplica o movimento aos vértices (cria o efeito de vento arrepiante)
	VERTEX.x += sway * wind_strength;
	VERTEX.z += shiver * (wind_strength * 0.8);
}

void fragment() {
	// Lê a textura da sua folha de pinheiro
	vec4 albedo_tex = texture(texture_albedo, UV);
	
	// Aplica a cor e a transparência
	ALBEDO = albedo_tex.rgb;
	ALPHA = albedo_tex.a;
	
	// Isso recorta o fundo "quadrado" invisível da textura da folha
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
}
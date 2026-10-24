extends Node2D

# Imagens do jogo (mantenha estes arquivos na pasta do projeto)
var textura_kart_vermelho = preload("res://kart_vermelho.png")
var textura_kart_brasil = preload("res://kart_brasil.png")
var textura_torcida_vermelha = preload("res://torcida_vermelha.png")
var textura_torcida_brasil = preload("res://torcida_brasil.png")
var textura_piloto_vermelho = preload("res://piloto_vermelho.png")
var textura_piloto_brasil = preload("res://piloto_brasil.png")

# Deslocamento visual da pista e da torcida
var faixa_offset = 0.0
var borda_offset = 0.0
var torcida_offset = 0.0
var linhas_velocidade_offset = 0.0

# Velocidades visuais (não alteram o avanço dos karts)
var velocidade_pista = 360.0
var velocidade_linhas = 620.0

# Progresso dos competidores: 0.0 = início, 1.0 = chegada
var progresso_vermelho = 0.0
var progresso_azul = 0.0
var vencedor = ""

# Vitórias acumuladas
# C reinicia somente a corrida; S zera somente as vitórias.
var vitorias_vermelho = 0
var vitorias_azul = 0

# Elementos de interface
var aviso_vencedor = null
var label_vermelho = null
var label_azul = null
var label_piloto_vermelho = null
var label_piloto_brasil = null

# Avanço normal e recuo do adversário
var avancar_jogador = 0.05
var recuar_adversario = 0.015

# Avanço extra das rosas simuladas
var impulso_rosa = 0.10
var recuo_rosa = 0.02


func _ready():
	var tamanho = get_viewport_rect().size
	var largura = tamanho.x
	var altura = tamanho.y

	# Aviso de vencedor
	aviso_vencedor = Label.new()
	aviso_vencedor.name = "AvisoVencedor"
	aviso_vencedor.align = Label.ALIGN_CENTER
	aviso_vencedor.valign = Label.VALIGN_CENTER
	aviso_vencedor.add_color_override(
		"font_color",
		Color(1.0, 1.0, 1.0)
	)
	aviso_vencedor.rect_position = Vector2(
		0,
		altura * 0.765
	)
	aviso_vencedor.rect_size = Vector2(
		largura,
		altura * 0.055
	)
	aviso_vencedor.visible = false
	add_child(aviso_vencedor)

	# Placar superior do kart vermelho
	label_vermelho = Label.new()
	label_vermelho.name = "PlacarVermelho"
	label_vermelho.align = Label.ALIGN_CENTER
	label_vermelho.valign = Label.VALIGN_CENTER
	label_vermelho.add_color_override(
		"font_color",
		Color(1.0, 0.55, 0.50)
	)
	label_vermelho.rect_position = Vector2(
		largura * 0.15,
		altura * 0.038
	)
	label_vermelho.rect_size = Vector2(
		largura * 0.30,
		altura * 0.035
	)
	add_child(label_vermelho)

	# Placar superior do kart Brasil
	label_azul = Label.new()
	label_azul.name = "PlacarBrasil"
	label_azul.align = Label.ALIGN_CENTER
	label_azul.valign = Label.VALIGN_CENTER
	label_azul.add_color_override(
		"font_color",
		Color(0.55, 0.80, 1.0)
	)
	label_azul.rect_position = Vector2(
		largura * 0.55,
		altura * 0.038
	)
	label_azul.rect_size = Vector2(
		largura * 0.30,
		altura * 0.035
	)
	add_child(label_azul)

	# Nome do piloto vermelho
	label_piloto_vermelho = Label.new()
	label_piloto_vermelho.name = "NomePilotoVermelho"
	label_piloto_vermelho.text = "LULA"
	label_piloto_vermelho.align = Label.ALIGN_CENTER
	label_piloto_vermelho.valign = Label.VALIGN_CENTER
	label_piloto_vermelho.add_color_override(
		"font_color",
		Color(1.0, 0.80, 0.78)
	)
	label_piloto_vermelho.rect_position = Vector2(
		largura * 0.04,
		altura * 0.945
	)
	label_piloto_vermelho.rect_size = Vector2(
		largura * 0.42,
		altura * 0.035
	)
	add_child(label_piloto_vermelho)

	# Nome do piloto Brasil
	label_piloto_brasil = Label.new()
	label_piloto_brasil.name = "NomePilotoBrasil"
	label_piloto_brasil.text = "FLAVIO"
	label_piloto_brasil.align = Label.ALIGN_CENTER
	label_piloto_brasil.valign = Label.VALIGN_CENTER
	label_piloto_brasil.add_color_override(
		"font_color",
		Color(0.78, 0.91, 1.0)
	)
	label_piloto_brasil.rect_position = Vector2(
		largura * 0.54,
		altura * 0.945
	)
	label_piloto_brasil.rect_size = Vector2(
		largura * 0.42,
		altura * 0.035
	)
	add_child(label_piloto_brasil)

	_atualizar_interface()
	update()


func _process(delta):
	# A pista, as zebras e as torcidas continuam em movimento.
	faixa_offset = fmod(
		faixa_offset + velocidade_pista * delta,
		90.0
	)
	borda_offset = fmod(
		borda_offset + velocidade_pista * delta,
		60.0
	)
	torcida_offset += velocidade_pista * delta

	linhas_velocidade_offset = fmod(
		linhas_velocidade_offset + velocidade_linhas * delta,
		1000.0
	)

	update()


func _input(event):
	# Clique do mouse: clicar diretamente em um kart faz avançá-lo.
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			_processar_clique(event.position)
		return

	# Toque na tela: também permite tocar diretamente em um kart.
	if event is InputEventScreenTouch:
		if event.pressed:
			_processar_clique(event.position)
		return

	# Controles pelo teclado.
	if event is InputEventKey and event.pressed and not event.echo:

		# C reinicia a corrida, mas preserva as vitórias acumuladas.
		if event.scancode == KEY_C:
			_reiniciar_corrida()
			return

		# S zera somente as vitórias, sem reiniciar a corrida.
		if event.scancode == KEY_S:
			_zerar_placar_vitorias()
			return

		# Depois do resultado, bloqueia os movimentos até reiniciar.
		if vencedor != "":
			return

		if event.scancode == KEY_R:
			_avancar_vermelho(false)
		elif event.scancode == KEY_B:
			_avancar_brasil(false)
		elif event.scancode == KEY_G:
			_avancar_vermelho(true)
		elif event.scancode == KEY_H:
			_avancar_brasil(true)
		else:
			return

		_finalizar_movimento()


func _processar_clique(posicao):
	# Não aceita cliques de corrida depois que alguém venceu.
	if vencedor != "":
		return

	var posicoes = _calcular_posicoes_karts()

	var retangulo_vermelho = _retangulo_kart(
		posicoes[0],
		textura_kart_vermelho
	)

	var retangulo_brasil = _retangulo_kart(
		posicoes[1],
		textura_kart_brasil
	)

	# Aumenta a área clicável sem mudar o tamanho visual do kart.
	if retangulo_vermelho.grow(12.0).has_point(posicao):
		_avancar_vermelho(false)
		_finalizar_movimento()
	elif retangulo_brasil.grow(12.0).has_point(posicao):
		_avancar_brasil(false)
		_finalizar_movimento()


func _avancar_vermelho(usar_rosa = false):
	var impulso = avancar_jogador
	var recuo = recuar_adversario

	if usar_rosa:
		impulso = impulso_rosa
		recuo = recuo_rosa

	progresso_vermelho = min(
		progresso_vermelho + impulso,
		1.0
	)
	progresso_azul = max(
		progresso_azul - recuo,
		0.0
	)


func _avancar_brasil(usar_rosa = false):
	var impulso = avancar_jogador
	var recuo = recuar_adversario

	if usar_rosa:
		impulso = impulso_rosa
		recuo = recuo_rosa

	progresso_azul = min(
		progresso_azul + impulso,
		1.0
	)
	progresso_vermelho = max(
		progresso_vermelho - recuo,
		0.0
	)


func _finalizar_movimento():
	_verificar_vencedor()
	_atualizar_interface()
	update()


func _reiniciar_corrida():
	# Reinicia o andamento, sem zerar as vitórias.
	progresso_vermelho = 0.0
	progresso_azul = 0.0
	vencedor = ""

	if aviso_vencedor != null:
		aviso_vencedor.text = ""
		aviso_vencedor.visible = false

	_atualizar_interface()
	update()


func _zerar_placar_vitorias():
	# Zera apenas as vitórias acumuladas.
	# O progresso e o resultado atual permanecem intactos.
	vitorias_vermelho = 0
	vitorias_azul = 0

	_atualizar_interface()
	update()

	print("Placar de vitórias zerado!")


func _verificar_vencedor():
	# Impede contar a mesma vitória mais de uma vez.
	if vencedor != "":
		return

	if progresso_vermelho >= 1.0 and progresso_azul >= 1.0:
		vencedor = "EMPATE!"

	elif progresso_vermelho >= 1.0:
		vencedor = "VENCEDOR: KART LULAAA"
		vitorias_vermelho += 1

	elif progresso_azul >= 1.0:
		vencedor = "VENCEDOR: FLAVIOOO"
		vitorias_azul += 1

	if vencedor != "":
		aviso_vencedor.text = vencedor
		aviso_vencedor.visible = true


func _atualizar_interface():
	if label_vermelho != null:
		var percentual_vermelho = int(
			round(progresso_vermelho * 100.0)
		)

		label_vermelho.text = (
			"LULA "
			+ str(percentual_vermelho)
			+ "% | V:"
			+ str(vitorias_vermelho)
		)

	if label_azul != null:
		var percentual_azul = int(
			round(progresso_azul * 100.0)
		)

		label_azul.text = (
			"FLAVIO "
			+ str(percentual_azul)
			+ "% | V:"
			+ str(vitorias_azul)
		)


func _calcular_posicoes_karts():
	var tamanho = get_viewport_rect().size
	var largura = tamanho.x
	var altura = tamanho.y

	var esquerda = largura * 0.15
	var largura_pista = largura * 0.70
	var linha_chegada_y = altura * 0.08
	var altura_kart = altura * 0.14
	var inicio_y = altura * 0.70
	var frente_final_y = linha_chegada_y + altura_kart / 2.0

	var vermelho_x = esquerda + largura_pista * 0.30
	var brasil_x = esquerda + largura_pista * 0.70

	var vermelho_y = lerp(
		inicio_y,
		frente_final_y,
		progresso_vermelho
	)

	var brasil_y = lerp(
		inicio_y,
		frente_final_y,
		progresso_azul
	)

	return [
		Vector2(vermelho_x, vermelho_y),
		Vector2(brasil_x, brasil_y)
	]


func _retangulo_kart(centro, textura):
	var altura_kart = get_viewport_rect().size.y * 0.14
	var proporcao = float(textura.get_width()) / float(textura.get_height())
	var largura_kart = altura_kart * proporcao

	return Rect2(
		centro - Vector2(largura_kart / 2.0, altura_kart / 2.0),
		Vector2(largura_kart, altura_kart)
	)


func _draw():
	var tamanho = get_viewport_rect().size
	var largura = tamanho.x
	var altura = tamanho.y

	var esquerda = largura * 0.15
	var largura_pista = largura * 0.70

	# Gramado
	draw_rect(
		Rect2(Vector2.ZERO, tamanho),
		Color(0.10, 0.29, 0.13)
	)

	# Linhas suaves no gramado, acompanhando o movimento da pista.
	for i in range(-1, int(altura / 65.0) + 2):
		var grama_y = float(i) * 65.0 + faixa_offset

		draw_line(
			Vector2(0, grama_y),
			Vector2(esquerda - 2.0, grama_y),
			Color(0.18, 0.36, 0.19, 0.45),
			1.0
		)

		draw_line(
			Vector2(esquerda + largura_pista + 2.0, grama_y),
			Vector2(largura, grama_y),
			Color(0.18, 0.36, 0.19, 0.45),
			1.0
		)

	# Asfalto
	draw_rect(
		Rect2(Vector2(esquerda, 0), Vector2(largura_pista, altura)),
		Color(0.16, 0.17, 0.19)
	)

	# Textura discreta do asfalto
	for i in range(-1, int(altura / 54.0) + 2):
		var textura_y = float(i) * 54.0 + faixa_offset * 0.60

		draw_line(
			Vector2(esquerda + 16.0, textura_y),
			Vector2(esquerda + largura_pista * 0.34, textura_y),
			Color(0.28, 0.29, 0.31, 0.40),
			1.0
		)

		draw_line(
			Vector2(esquerda + largura_pista * 0.68, textura_y + 17.0),
			Vector2(esquerda + largura_pista - 16.0, textura_y + 17.0),
			Color(0.28, 0.29, 0.31, 0.40),
			1.0
		)

	# Riscos curtos nas laterais do asfalto.
	_desenhar_linhas_velocidade(
		esquerda,
		largura_pista,
		altura
	)

	# Zebras laterais vermelhas e brancas
	var largura_zebra = 8.0
	var altura_zebra = 30.0

	for i in range(-1, int(altura / altura_zebra) + 2):
		var zebra_y = float(i) * altura_zebra + borda_offset
		var cor_zebra = Color(0.90, 0.12, 0.10)

		if _eh_impar(i):
			cor_zebra = Color(0.92, 0.92, 0.88)

		draw_rect(
			Rect2(
				Vector2(esquerda + 2.0, zebra_y),
				Vector2(largura_zebra, altura_zebra + 1.0)
			),
			cor_zebra
		)

		draw_rect(
			Rect2(
				Vector2(
					esquerda + largura_pista - largura_zebra - 2.0,
					zebra_y
				),
				Vector2(largura_zebra, altura_zebra + 1.0)
			),
			cor_zebra
		)

	# Torcida nas laterais, rolando junto com o cenário.
	var largura_torcida = max(
		12.0,
		min(largura * 0.095, esquerda - 8.0)
	)

	var x_torcida_esquerda = 3.0
	var x_torcida_direita = largura - largura_torcida - 3.0

	_desenhar_torcida_rolando(
		x_torcida_esquerda,
		largura_torcida,
		textura_torcida_vermelha
	)

	_desenhar_torcida_rolando(
		x_torcida_direita,
		largura_torcida,
		textura_torcida_brasil
	)

	# Linhas brancas das bordas da pista
	draw_line(
		Vector2(esquerda + 12.0, 0),
		Vector2(esquerda + 12.0, altura),
		Color(0.95, 0.95, 0.90),
		2.0
	)

	draw_line(
		Vector2(esquerda + largura_pista - 12.0, 0),
		Vector2(esquerda + largura_pista - 12.0, altura),
		Color(0.95, 0.95, 0.90),
		2.0
	)

	# Faixas centrais em movimento
	for i in range(-1, int(altura / 90.0) + 2):
		var faixa_y = float(i) * 90.0 + faixa_offset

		draw_rect(
			Rect2(
				Vector2(largura * 0.495, faixa_y),
				Vector2(largura * 0.01, 45.0)
			),
			Color(0.88, 0.88, 0.83)
		)

	# Linha quadriculada de chegada
	var linha_chegada_y = altura * 0.08
	var celulas = 20
	var celula_largura = largura_pista / float(celulas)
	var celula_altura = max(6.0, altura * 0.0125)

	for linha in range(2):
		for coluna in range(celulas):
			var cor_celula = Color(0.95, 0.95, 0.95)

			if not _eh_impar(coluna + linha):
				cor_celula = Color(0.06, 0.06, 0.06)

			draw_rect(
				Rect2(
					Vector2(
						esquerda + float(coluna) * celula_largura,
						linha_chegada_y + float(linha) * celula_altura
					),
					Vector2(celula_largura + 1.0, celula_altura + 1.0)
				),
				cor_celula
			)

	# Placar superior
	var painel_superior_y = altura * 0.008
	var painel_altura = altura * 0.067

	var painel_vermelho = Rect2(
		Vector2(largura * 0.105, painel_superior_y),
		Vector2(largura * 0.35, painel_altura)
	)

	draw_rect(
		painel_vermelho,
		Color(0.025, 0.03, 0.045, 0.88)
	)

	draw_rect(
		painel_vermelho,
		Color(0.78, 0.15, 0.13, 0.90),
		false,
		1.5
	)

	var painel_brasil = Rect2(
		Vector2(largura * 0.545, painel_superior_y),
		Vector2(largura * 0.35, painel_altura)
	)

	draw_rect(
		painel_brasil,
		Color(0.025, 0.03, 0.045, 0.88)
	)

	draw_rect(
		painel_brasil,
		Color(0.12, 0.48, 0.83, 0.90),
		false,
		1.5
	)

	# Barras de progresso no placar superior
	var barra_y = altura * 0.020
	var barra_largura = largura * 0.30
	var barra_altura = max(5.0, altura * 0.015)

	draw_rect(
		Rect2(
			Vector2(largura * 0.15, barra_y),
			Vector2(barra_largura, barra_altura)
		),
		Color(0.09, 0.09, 0.10)
	)

	draw_rect(
		Rect2(
			Vector2(largura * 0.15, barra_y),
			Vector2(barra_largura * progresso_vermelho, barra_altura)
		),
		Color(0.95, 0.10, 0.08)
	)

	draw_rect(
		Rect2(
			Vector2(largura * 0.55, barra_y),
			Vector2(barra_largura, barra_altura)
		),
		Color(0.09, 0.09, 0.10)
	)

	draw_rect(
		Rect2(
			Vector2(largura * 0.55, barra_y),
			Vector2(barra_largura * progresso_azul, barra_altura)
		),
		Color(0.10, 0.43, 0.98)
	)

	# Painel do vencedor
	if vencedor != "":
		var painel_vencedor = Rect2(
			Vector2(largura * 0.05, altura * 0.755),
			Vector2(largura * 0.90, altura * 0.065)
		)

		draw_rect(
			painel_vencedor,
			Color(0.025, 0.025, 0.035, 0.94)
		)

		draw_rect(
			painel_vencedor,
			Color(1.0, 0.78, 0.22, 0.95),
			false,
			2.0
		)

	# Karts da disputa
	var posicoes = _calcular_posicoes_karts()

	_desenhar_kart(
		posicoes[0],
		textura_kart_vermelho
	)

	_desenhar_kart(
		posicoes[1],
		textura_kart_brasil
	)

	# Retratos na parte inferior da tela
	_desenhar_pilotos(largura, altura)


func _desenhar_pilotos(largura, altura):
	var y = altura * 0.845
	var largura_cartao = largura * 0.42
	var altura_cartao = altura * 0.13
	var x_vermelho = largura * 0.04
	var x_brasil = largura * 0.54

	var cartao_vermelho = Rect2(
		Vector2(x_vermelho, y),
		Vector2(largura_cartao, altura_cartao)
	)

	draw_rect(
		cartao_vermelho,
		Color(0.025, 0.03, 0.045, 0.90)
	)

	draw_rect(
		cartao_vermelho,
		Color(0.78, 0.15, 0.13, 0.95),
		false,
		1.5
	)

	_desenhar_imagem_piloto(
		textura_piloto_vermelho,
		x_vermelho + largura_cartao / 2.0,
		y + 2.0,
		largura_cartao * 0.56,
		altura_cartao * 0.72
	)

	var cartao_brasil = Rect2(
		Vector2(x_brasil, y),
		Vector2(largura_cartao, altura_cartao)
	)

	draw_rect(
		cartao_brasil,
		Color(0.025, 0.03, 0.045, 0.90)
	)

	draw_rect(
		cartao_brasil,
		Color(0.10, 0.48, 0.20, 0.95),
		false,
		1.5
	)

	_desenhar_imagem_piloto(
		textura_piloto_brasil,
		x_brasil + largura_cartao / 2.0,
		y + 2.0,
		largura_cartao * 0.56,
		altura_cartao * 0.72
	)


func _desenhar_imagem_piloto(
	textura,
	centro_x,
	topo_y,
	largura_maxima,
	altura_maxima
):
	# Ajusta a imagem ao cartão sem esticar nem deformar o piloto.
	var largura_original = float(textura.get_width())
	var altura_original = float(textura.get_height())

	if largura_original <= 0.0 or altura_original <= 0.0:
		return

	var escala_x = largura_maxima / largura_original
	var escala_y = altura_maxima / altura_original
	var escala = min(escala_x, escala_y)

	var largura_imagem = largura_original * escala
	var altura_imagem = altura_original * escala
	var x = centro_x - largura_imagem / 2.0

	draw_texture_rect(
		textura,
		Rect2(
			Vector2(x, topo_y),
			Vector2(largura_imagem, altura_imagem)
		),
		false
	)


func _desenhar_linhas_velocidade(esquerda, largura_pista, altura):
	# Linhas rápidas nas bordas da pista.
	for i in range(10):
		var variacao = _variacao_tres(i)

		var y = fmod(
			float(i) * 105.0 + linhas_velocidade_offset,
			altura + 100.0
		) - 50.0

		var comprimento = 22.0 + variacao * 9.0
		var x_esquerda = esquerda + 18.0 + variacao * 5.0
		var x_direita = esquerda + largura_pista - 18.0 - variacao * 5.0
		var cor_risco = Color(0.82, 0.84, 0.87, 0.24)

		draw_line(
			Vector2(x_esquerda, y),
			Vector2(x_esquerda, y + comprimento),
			cor_risco,
			2.0
		)

		draw_line(
			Vector2(x_direita, y + 28.0),
			Vector2(x_direita, y + 28.0 + comprimento),
			cor_risco,
			2.0
		)


func _desenhar_torcida_rolando(x, largura_torcida, textura):
	var altura_tela = get_viewport_rect().size.y

	var altura_natural = (
		largura_torcida
		* float(textura.get_height())
		/ float(textura.get_width())
	)

	var altura_tile = max(100.0, altura_natural)
	var deslocamento = fmod(torcida_offset, altura_tile)

	for i in range(-1, int(altura_tela / altura_tile) + 2):
		var y = float(i) * altura_tile + deslocamento - altura_tile

		draw_texture_rect(
			textura,
			Rect2(
				Vector2(x, y),
				Vector2(largura_torcida, altura_tile)
			),
			false
		)


func _desenhar_kart(centro, textura):
	draw_texture_rect(
		textura,
		_retangulo_kart(centro, textura),
		false
	)


# Alternância par/ímpar sem usar o operador %.
func _eh_impar(valor):
	var numero = int(valor)
	var metade = int(float(numero) / 2.0)
	var resto = numero - metade * 2

	return resto != 0


# Retorna 0, 1 ou 2 sem usar o operador %.
func _variacao_tres(valor):
	var numero = abs(int(valor))
	var grupos = int(float(numero) / 3.0)
	var resto = numero - grupos * 3

	return float(resto)

-- Garagem do modo historia: o seu carro, dinheiro, ranking e o PASSWORD; daqui sai para a
-- proxima corrida (3 a escolher, e as minas, compradas antes de cada corrida, como no Death
-- Rally), a oficina (melhorias), a concessionaria (carros), o ranking e, no 1o lugar, o desafio
-- final (campeonato.lua tem as regras).
local Entrada = require "entrada"
local Cores = require "cores"
local Carros = require "carros"
local Pista = require "pista"
local Menu = require "menu"
local Campeonato = require "campeonato"
local Rapida = require "telas.rapida"
local Texto = require "texto"
local C = require "config"
local DT = require "dados_telas"

local Tela = {}
Tela.__index = Tela

local function dinheiro(v)
  local s = tostring(math.floor(v))
  local partes = {}
  while #s > 3 do
    table.insert(partes, 1, s:sub(-3))
    s = s:sub(1, -4)
  end
  table.insert(partes, 1, s)
  return "$" .. table.concat(partes, ".")
end
Tela.dinheiro = dinheiro

local NOME_DIFICULDADE = { facil = "F\xC1CIL", medio = "M\xC9DIA", dificil = "DIF\xCDCIL" }

function Tela.nova()
  local t = setmetatable({ modo = "menu", aviso = nil, aviso_t = 0, confirmar = nil, minas = false }, Tela)
  t.e = Jogo.campeonato
  t:montar()
  return t
end

-- textos que so mudam quando o estado muda (dinheiro, carro, ranking...)
function Tela:montar()
  local e = self.e
  local m = Campeonato.modelo(e)
  local rank = Campeonato.ranking(e)
  local pos = Campeonato.posicao(e)
  self.modelo = m
  self.melhorias = string.format("MOTOR %d/3 PNEU %d/3 BLIND %d/3", e.motor, e.pneus, e.blindagem)
  self.dinheiro = dinheiro(e.dinheiro)
  self.posicao = string.format("%d\xBA DE %d", pos, #rank)
  self.pontos = string.format("(%d PONTOS)", e.pontos)
  local lider = rank[1].jogador and rank[2] or rank[1]
  self.lider = pos == 1 and "O ADVERSARIO TE ESPERA!"
    or string.format("LIDER: %s (%d)", lider.nome, lider.pontos)
  self.senha = Campeonato.senha_bonita(e)
  self.nivel = "RIVAIS " .. Campeonato.nivel(e).id:upper()
  self.rank = rank
  self.corridas = Campeonato.corridas(e)

  local opcoes = {
    { texto = "PR\xD3XIMA CORRIDA", acao = function() self:ir("corridas") end },
    { texto = "OFICINA", acao = function() self:ir("oficina") end },
    { texto = "CONCESSION\xC1RIA", acao = function() self:ir("loja") end },
    { texto = "RANKING", acao = function() self:ir("ranking") end },
  }
  if Campeonato.desafio_aberto(e) then
    table.insert(opcoes, 1, { texto = "DESAFIO FINAL", acao = function() self:ir("desafio") end })
  end
  opcoes[#opcoes + 1] = { texto = "SAIR", acao = function() Jogo.ir("titulo") end }
  local escolha = self.menu and self.menu.escolha or 1
  self.menu = Menu.novo(opcoes, 44, 40, 22, 206)
  if escolha <= #opcoes then self.menu.escolha = escolha end

  -- as 3 corridas da rodada
  local lista = {}
  for _, c in ipairs(self.corridas) do
    lista[#lista + 1] = { texto = NOME_DIFICULDADE[c.dificuldade.id] or c.dificuldade.nome, acao = function() self:correr(c) end }
  end
  -- minas: so a metralhadora vem de fabrica; o pacote vale para a proxima corrida
  lista[#lista + 1] = { texto = "MINAS", valor = function() return self.minas and "SIM" or "N\xC3O" end,
                        acao = function() self.minas = not self.minas end }
  lista[#lista + 1] = { texto = "VOLTAR", acao = function() self:ir("menu") end }
  local esc_corridas = self.menu_corridas and self.menu_corridas.escolha or 1
  self.menu_corridas = Menu.novo(lista, 44, 40, 22, 150)
  self.menu_corridas.escolha = esc_corridas

  -- oficina
  local of = {}
  for _, qual in ipairs(Campeonato.MELHORIAS) do
    of[#of + 1] = {
      texto = function()
        local preco = Campeonato.preco_melhoria(e, qual)
        return string.format("%-10s NIVEL %d/3   %s", Campeonato.NOME_MELHORIA[qual], e[qual],
          preco and dinheiro(preco) or "NO MAXIMO")
      end,
      acao = function()
        if Campeonato.comprar_melhoria(e, qual) then self:avisar("COMPRADO!") self:montar()
        elseif not Campeonato.preco_melhoria(e, qual) then self:avisar("JA ESTA NO NIVEL MAXIMO")
        else self:avisar("DINHEIRO INSUFICIENTE") end
      end,
    }
  end
  of[#of + 1] = { texto = "VOLTAR", acao = function() self:ir("menu") end }
  local esc_of = self.menu_oficina and self.menu_oficina.escolha or 1
  self.menu_oficina = Menu.novo(of, 84, 66, 50, 222, true)
  self.menu_oficina.escolha = esc_of

  -- concessionaria
  local loja = {}
  for i, mod in ipairs(Carros) do
    loja[#loja + 1] = {
      texto = function()
        if i == e.carro then return string.format("%-8s  O SEU", mod.nome) end
        return string.format("%-8s %8s", mod.nome, dinheiro(Campeonato.PRECO_CARRO[mod.id]))
      end,
      acao = function() self:comprar_carro(i) end,
    }
  end
  loja[#loja + 1] = { texto = "VOLTAR", acao = function() self:ir("menu") end }
  local esc_loja = self.menu_loja and self.menu_loja.escolha or 1
  self.menu_loja = Menu.novo(loja, 26, 42, 16, 144, true)
  self.menu_loja.escolha = esc_loja
end

function Tela:ir(modo)
  self.modo = modo
  self.confirmar = nil
  if modo == "menu" then self.aviso_t = 0 end   -- o aviso fica embaixo, onde o menu mostra o password
end

function Tela:avisar(texto)
  self.aviso, self.aviso_t = texto, 150
end

function Tela:comprar_carro(i)
  local e = self.e
  if i == e.carro then self:avisar("ESTE JA E O SEU CARRO") return end
  if Campeonato.preco_troca(e, i) > e.dinheiro then self:avisar("DINHEIRO INSUFICIENTE") return end
  if self.confirmar ~= i then
    self.confirmar = i
    self:avisar("APERTE " .. Entrada.NOME.confirmar .. " DE NOVO PARA COMPRAR (AS MELHORIAS DO SEU NAO VAO JUNTO)")
    return
  end
  Campeonato.comprar_carro(e, i)
  self.confirmar = nil
  self:avisar("CARRO NOVO NA GARAGEM!")
  self:montar()
end

function Tela:correr(corrida)
  if self.minas and self.e.dinheiro < C.PRECO_MINAS then
    self:avisar("DINHEIRO INSUFICIENTE PARA AS MINAS")
    return
  end
  Jogo.ir("corrida", Campeonato.opcoes_da_corrida(self.e, corrida, self.minas))
end

function Tela:atualizar()
  if self.aviso_t > 0 then self.aviso_t = self.aviso_t - 1 end
  local modo = self.modo
  if modo == "menu" then
    self.menu:atualizar()
  elseif modo == "ranking" then
    if Entrada.voltar() or Entrada.confirmar() then self:ir("menu") end
  elseif modo == "desafio" then
    if Entrada.voltar() then self:ir("menu")
    elseif Entrada.confirmar() then self:correr(Campeonato.desafio(self.e)) end
  else
    -- cartazes das corridas: o direcional para os lados tambem troca de cartaz
    if modo == "corridas" and self.menu_corridas.escolha <= 3 then
      local m = self.menu_corridas
      if Entrada.esq() then m.escolha = (m.escolha + 1) % 3 + 1 end
      if Entrada.dir() then m.escolha = m.escolha % 3 + 1 end
    end
    if Entrada.voltar() then self:ir("menu") return end
    local m = modo == "corridas" and self.menu_corridas or (modo == "oficina" and self.menu_oficina or self.menu_loja)
    local antes = m.escolha
    m:atualizar()
    if m.escolha ~= antes then self.confirmar = nil end
  end
end

-- ---------------------------------------------------------------- desenho
local function retrato16(n, x, y) ui.tile(Sprites.img.ui.ret16, n, x, y) end

-- opcao de menu solta (como em menu.lua), para as opcoes embaixo dos cartazes
local function opcao(texto, x, y, largura, escolhida)
  if escolhida then
    ui.rectfill(x - 22, y - 2, x - 22 + largura - 1, y + 15, Cores.vinho)
    Texto.extra("palheta", x - 18, y)
  end
  Texto.escrever("f2", texto, x, y, escolhida and "amarelo" or "branco")
end

-- faixa preta embaixo, para o rodape ficar legivel por cima da arte
local function faixa_rodape()
  ui.rectfill(0, 255, 479, 269, Cores.preto)
end

function Tela:desenhar_menu()
  Menu.imagem("garagem")
  Menu.painel(8, 32, 228, 186)
  self.menu:desenhar()
  -- dinheiro e ranking embaixo do menu
  Texto.escrever("f2", self.dinheiro, 24, 170, "amarelo")
  local w = Texto.escrever("f2", self.posicao, 24, 190, "branco")
  ui.print(self.pontos, 30 + w, 194, Cores.cinza)
  ui.print(self.lider, 24, 208, Cores.cinza_claro)
  -- o seu carro: a ficha num painel e o carro no chao da oficina
  local m = self.modelo
  Menu.painel(296, 32, 176, 102)
  Texto.escrever("f2", m.nome, 304, 38, "amarelo")
  ui.print(self.melhorias, 301, 56, Cores.cinza_claro)
  Rapida.ficha_barras(m, 304, 68)
  Rapida.carro(m, 372, 216)
  -- password
  Menu.painel(70, 222, 340, 31, Cores.amarelo_escuro)
  ui.print("PASSWORD:", 82, 234, Cores.cinza_claro)
  Texto.escrever("f3", self.senha, 150, 226, "amarelo")
  faixa_rodape()
end

local CARTAZ_X, CARTAZ_Y, CARTAZ_W, CARTAZ_H = { 59, 187, 315 }, 34, 106, 176

-- uma corrida da rodada como cartaz de show colado no mural: dificuldade, pista, mapinha, premio
-- do 1o lugar e os 3 rivais (retrato, nome e carro). A pista pode vir inversa e/ou espelhada.
function Tela:cartaz(c, x, escolhido)
  local y, w = CARTAZ_Y, CARTAZ_W
  Menu.painel(x, y, w, CARTAZ_H, escolhido and Cores.amarelo or Cores.cinza_escuro)
  if escolhido then Menu.painel(x + 1, y + 1, w - 2, CARTAZ_H - 2, Cores.amarelo) end
  local nome = NOME_DIFICULDADE[c.dificuldade.id] or c.dificuldade.nome
  local tw = Texto.largura("f2", nome)
  Texto.escrever("f2", nome, x + (w - tw) // 2, y + 5, escolhido and "amarelo" or "branco")
  local pista = Pista.LISTA[c.pista]
  local a, b = pista.nome:match("^(.-) %- (.+)$")
  local linhas = a and { a, b } or { pista.nome }
  local V = Pista.VARIANTES[c.variante or 1]
  for i, l in ipairs(linhas) do ui.print(l, x + (w - #l * 6) // 2, y + 16 + i * 9, Cores.cinza_claro) end
  if V.nome ~= "" then
    ui.print(V.nome, x + (w - #V.nome * 6) // 2, y + 16 + (#linhas + 1) * 9, Cores.amarelo)
  end
  Rapida.mapa(pista.id, x + w // 2, y + 54, V.espelho)
  local P = C.PREMIOS[c.dificuldade.id]
  local premio = "1o " .. dinheiro(P.posicao[1])
  ui.print(premio, x + (w - #premio * 6) // 2, y + 113, Cores.verde)
  for k, i in ipairs(c.rivais) do
    local ry = y + 125 + (k - 1) * 16
    retrato16(i - 1, x + 5, ry)
    ui.print(Campeonato.PILOTOS[i][1], x + 24, ry, Cores.branco)
    ui.print(Carros[Carros.indice(c.carros[k])].nome, x + 24, ry + 8, Cores.amarelo_escuro)
  end
end

function Tela:desenhar_corridas()
  Menu.imagem("mural")
  local esc = self.menu_corridas.escolha
  for k, c in ipairs(self.corridas) do self:cartaz(c, CARTAZ_X[k], k == esc) end
  -- embaixo: minas, voltar e o que vale a corrida escolhida (nas outras opcoes, a ultima)
  Menu.painel(8, 212, 464, 42)
  opcao("MINAS: " .. (self.minas and "SIM" or "N\xC3O"), 40, 215, 162, esc == 4)
  opcao("VOLTAR", 40, 234, 162, esc == 5)
  local c = self.corridas[esc] or self.ultima_corrida or self.corridas[1]
  self.ultima_corrida = c
  local P = C.PREMIOS[c.dificuldade.id]
  local pts = C.PONTOS_RANKING[c.dificuldade.id]
  ui.print(string.format("PONTOS: 1o +%d  2o +%d  3o +%d  ABATE +%d", pts[1], pts[2], pts[3], C.PONTOS_RANKING_ABATE),
    206, 216, Cores.amarelo)
  ui.print(string.format("PREMIO: 2o %s  3o %s  ABATE %s", dinheiro(P.posicao[2]), dinheiro(P.posicao[3]),
    dinheiro(P.abate)), 206, 228, Cores.verde)
  ui.print(string.format("MINAS: 3 POR %s, SO NESTA CORRIDA", dinheiro(C.PRECO_MINAS)), 206, 240,
    self.minas and Cores.verde or Cores.cinza)
  faixa_rodape()
end

local EXPLICA_MELHORIA = {
  motor = "MAIS VELOCIDADE (+4% POR NIVEL)",
  pneus = "ESCORREGA MENOS NAS CURVAS",
  blindagem = "AGUENTA MAIS TIRO, MINA E BATIDA",
}

function Tela:desenhar_oficina()
  Menu.imagem("garagem")
  Menu.painel(12, 32, 300, 214)
  ui.print("MELHORIAS DO SEU " .. self.modelo.nome, 22, 40, Cores.cinza_claro)
  self.menu_oficina:desenhar()
  local O = DT.oficina
  for k, qual in ipairs(Campeonato.MELHORIAS) do
    local y = 66 + (k - 1) * 50
    ui.tile(Sprites.img.ui.oficina, O[qual], 22, y - 14)
    ui.print(EXPLICA_MELHORIA[qual], 84, y + 14, Cores.cinza)
  end
  Menu.painel(320, 32, 152, 30)
  Texto.escrever("f2", self.dinheiro, 330, 39, "amarelo")
  Rapida.carro(self.modelo, 392, 216)
  faixa_rodape()
end

function Tela:desenhar_loja()
  Menu.imagem("concessionaria")
  Menu.painel(8, 32, 168, 172)
  self.menu_loja:desenhar()
  local i = self.menu_loja.escolha
  local mod = Carros[i]
  if mod then
    Menu.painel(300, 32, 172, 132)
    Texto.escrever("f2", mod.nome, 308, 38, "amarelo")
    if i == self.e.carro then
      ui.print("ESTE E O SEU CARRO", 308, 58, Cores.cinza_claro)
    else
      ui.print("PRECO: " .. dinheiro(Campeonato.PRECO_CARRO[mod.id]), 308, 58, Cores.branco)
      ui.print("COM A TROCA DO SEU:", 308, 70, Cores.cinza)
      ui.print(dinheiro(math.max(0, Campeonato.preco_troca(self.e, i))), 308, 80, Cores.verde)
    end
    Rapida.ficha_barras(mod, 308, 96)
    Rapida.carro(mod, 238, 226)
  end
  Menu.painel(8, 208, 168, 44)
  ui.print("SEU DINHEIRO:", 16, 214, Cores.cinza)
  Texto.escrever("f2", self.dinheiro, 16, 230, "amarelo")
  faixa_rodape()
end

function Tela:desenhar_ranking()
  Menu.fundo()
  for i, l in ipairs(self.rank) do
    local col, lin = (i - 1) // 10, (i - 1) % 10
    local x, y = 44 + col * 216, 40 + lin * 18
    if l.jogador then ui.rectfill(x - 26, y - 5, x + 187, y + 12, Cores.vinho) end
    retrato16(l.jogador and DT.retrato.jogador or l.rival - 1, x - 22, y - 4)
    local cor = l.jogador and Cores.amarelo or Cores.branco
    ui.print(string.format("%2d. %-10s %-7s %3d PTS", i, l.nome, Carros[l.carro].nome, l.pontos), x, y, cor)
  end
  Menu.centro("1o LUGAR DO RANKING: ABRE O DESAFIO FINAL CONTRA O ADVERSARIO", 226, Cores.cinza_claro)
end

local FALA = {
  "\"ENTAO VOCE E O MOLEQUE QUE SUBIU O RANKING",
  "INTEIRO COM UM FUSCA VELHO...\"",
  "",
  "\"A LIGA E MINHA. NO PORTO, EU, VOCE E OS",
  "DOIS MELHORES. SE GANHAR, ELA E SUA.\"",
}

function Tela:desenhar_desafio()
  Menu.fundo()
  Menu.painel(24, 48, 432, 170, Cores.vermelho)
  ui.spr(Sprites.img.tela.adversario, 40, 66)
  Texto.escrever("f2", "O ADVERS\xC1RIO", 152, 60, "amarelo")
  for i, l in ipairs(FALA) do ui.print(l, 152, 72 + i * 13, Cores.branco) end
  ui.print("PREMIO: " .. dinheiro(C.PREMIOS.final.posicao[1]) .. " E O TITULO DA LIGA", 152, 160, Cores.verde)
  ui.print("ELE PILOTA UM PUMA ENVENENADO.", 152, 176, Cores.cinza_claro)
  ui.print(self.nivel, 152, 192, Cores.cinza)
end

local TITULOS = { menu = "GARAGEM", corridas = "PR\xD3XIMA CORRIDA", oficina = "OFICINA",
                  loja = "CONCESSION\xC1RIA", ranking = "RANKING", desafio = "DESAFIO FINAL" }

function Tela:desenhar()
  local modo = self.modo
  if modo == "menu" then self:desenhar_menu()
  elseif modo == "corridas" then self:desenhar_corridas()
  elseif modo == "oficina" then self:desenhar_oficina()
  elseif modo == "loja" then self:desenhar_loja()
  elseif modo == "desafio" then self:desenhar_desafio()
  else self:desenhar_ranking() end
  Menu.cabecalho(TITULOS[modo], "RODADA " .. (self.e.rodada + 1) .. (modo == "menu" and "  " .. self.nivel or ""))
  if self.aviso_t > 0 then
    local w = #self.aviso * 6
    ui.rectfill(240 - w // 2 - 6, 241, 240 + w // 2 + 5, 254, Cores.vinho)
    Menu.centro(self.aviso, 244, Cores.branco)
  end
  if modo == "menu" then
    Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER    O CONSOLE NAO GUARDA O JOGO: ANOTE O PASSWORD")
  elseif modo == "desafio" then
    Menu.rodape(Entrada.NOME.confirmar .. ": ACEITAR O DESAFIO   " .. Entrada.NOME.voltar .. ": VOLTAR")
  elseif modo == "corridas" then
    Menu.rodape(Entrada.NOME.confirmar .. ": CORRER   SETAS: ESCOLHER   " .. Entrada.NOME.voltar .. ": VOLTAR")
  else
    Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER   " .. Entrada.NOME.voltar .. ": VOLTAR")
  end
end

return Tela

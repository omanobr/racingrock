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
  self.melhorias = string.format("MOTOR %d/3  PNEUS %d/3  BLIND %d/3", e.motor, e.pneus, e.blindagem)
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
    table.insert(opcoes, 1, { texto = "DESAFIO FINAL", acao = function() self:correr(Campeonato.desafio(e)) end })
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
  self.menu_oficina = Menu.novo(of, 40, 56, 18, 300, true)
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
  self.menu_loja = Menu.novo(loja, 40, 42, 16, 150, true)
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
  else
    if Entrada.voltar() then self:ir("menu") return end
    local m = modo == "corridas" and self.menu_corridas or (modo == "oficina" and self.menu_oficina or self.menu_loja)
    local antes = m.escolha
    m:atualizar()
    if m.escolha ~= antes then self.confirmar = nil end
  end
end

-- ---------------------------------------------------------------- desenho
function Tela:desenhar_menu()
  self.menu:desenhar()
  -- dinheiro e ranking embaixo do menu
  Texto.escrever("f2", self.dinheiro, 24, 170, "amarelo")
  local w = Texto.escrever("f2", self.posicao, 24, 190, "branco")
  ui.print(self.pontos, 30 + w, 194, Cores.cinza)
  ui.print(self.lider, 24, 210, Cores.cinza_claro)
  -- o seu carro
  local m = self.modelo
  Menu.painel(240, 34, 228, 184)
  Texto.escrever("f2", m.nome, 250, 40, "amarelo")
  ui.print(self.melhorias, 250, 58, Cores.cinza_claro)
  Rapida.carro(m, 354, 150)
  Rapida.ficha_barras(m, 250, 156)
  -- password
  Menu.painel(70, 222, 340, 31, Cores.amarelo_escuro)
  ui.print("PASSWORD:", 82, 234, Cores.cinza_claro)
  Texto.escrever("f3", self.senha, 150, 226, "amarelo")
end

function Tela:desenhar_corridas()
  self.menu_corridas:desenhar()
  -- a corrida escolhida (nas opcoes MINAS e VOLTAR, a ultima que estava escolhida)
  local c = self.corridas[self.menu_corridas.escolha] or self.ultima_corrida or self.corridas[1]
  self.ultima_corrida = c
  local P = C.PREMIOS[c.dificuldade.id]
  local pts = C.PONTOS_RANKING[c.dificuldade.id]
  local pista = Pista.LISTA[c.pista]
  Menu.painel(200, 34, 268, 112)
  ui.print("PISTA", 210, 42, Cores.cinza)
  ui.print(pista.nome, 210, 54, Cores.branco)
  ui.print(pista.voltas .. " VOLTAS", 210, 66, Cores.cinza_claro)
  Rapida.mapa(pista.id, 400, 76)
  Menu.painel(12, 152, 456, 98)
  local y = 160
  ui.print(string.format("PREMIO: 1o %s  2o %s  3o %s   ABATE %s", dinheiro(P.posicao[1]), dinheiro(P.posicao[2]),
    dinheiro(P.posicao[3]), dinheiro(P.abate)), 22, y, Cores.verde)
  ui.print(string.format("PONTOS NO RANKING: 1o +%d  2o +%d  3o +%d   ABATE +%d", pts[1], pts[2], pts[3],
    C.PONTOS_RANKING_ABATE), 22, y + 13, Cores.amarelo)
  ui.print("RIVAIS:", 22, y + 32, Cores.cinza_claro)
  for k, i in ipairs(c.rivais) do
    local p = Campeonato.PILOTOS[i]
    ui.print(string.format("%-10s %s", p[1], Carros[Carros.indice(c.carros[k])].nome), 82, y + 32 + (k - 1) * 13,
      Cores.branco)
  end
  ui.print(string.format("MINAS: 3 POR %s, SO PARA ESTA CORRIDA", dinheiro(C.PRECO_MINAS)), 22, y + 76,
    self.minas and Cores.verde or Cores.cinza)
end

function Tela:desenhar_oficina()
  ui.print("MELHORIAS DO SEU " .. self.modelo.nome, 30, 38, Cores.cinza_claro)
  Texto.escrever("f2", self.dinheiro, 360, 34, "amarelo")
  self.menu_oficina:desenhar()
  Rapida.carro(self.modelo, 400, 146)
  ui.print("MOTOR: MAIS VELOCIDADE E ARRANQUE (+4% POR NIVEL)", 40, 162, Cores.cinza_claro)
  ui.print("PNEUS: ESCORREGA MENOS NAS CURVAS", 40, 176, Cores.cinza_claro)
  ui.print("BLINDAGEM: AGUENTA MAIS TIRO, MINA E BATIDA", 40, 190, Cores.cinza_claro)
end

function Tela:desenhar_loja()
  self.menu_loja:desenhar()
  local i = self.menu_loja.escolha
  local mod = Carros[i]
  Menu.painel(196, 34, 272, 184)
  if mod then
    Texto.escrever("f2", mod.nome, 206, 40, "amarelo")
    Rapida.carro(mod, 332, 140)
    if i == self.e.carro then
      ui.print("ESTE E O SEU CARRO", 206, 150, Cores.cinza_claro)
    else
      ui.print("PRECO: " .. dinheiro(Campeonato.PRECO_CARRO[mod.id]), 206, 150, Cores.branco)
      ui.print("COM A TROCA", 206, 166, Cores.cinza)
      ui.print("DO SEU: " .. dinheiro(math.max(0, Campeonato.preco_troca(self.e, i))), 206, 178, Cores.verde)
    end
    Rapida.ficha_barras(mod, 340, 150)
  end
  ui.print("SEU DINHEIRO:", 30, 212, Cores.cinza)
  Texto.escrever("f2", self.dinheiro, 30, 222, "amarelo")
end

function Tela:desenhar_ranking()
  for i, l in ipairs(self.rank) do
    local col, lin = (i - 1) // 10, (i - 1) % 10
    local x, y = 40 + col * 210, 40 + lin * 17
    if l.jogador then ui.rectfill(x - 6, y - 4, x + 183, y + 10, Cores.vinho) end
    local cor = l.jogador and Cores.amarelo or Cores.branco
    ui.print(string.format("%2d. %-10s %-7s %3d PTS", i, l.nome, Carros[l.carro].nome, l.pontos), x, y, cor)
  end
  Menu.centro("1o LUGAR DO RANKING: ABRE O DESAFIO FINAL CONTRA O ADVERSARIO", 222, Cores.cinza_claro)
end

local TITULOS = { menu = "GARAGEM", corridas = "PR\xD3XIMA CORRIDA", oficina = "OFICINA",
                  loja = "CONCESSION\xC1RIA", ranking = "RANKING" }

function Tela:desenhar()
  Menu.fundo()
  Menu.cabecalho(TITULOS[self.modo], "RODADA " .. (self.e.rodada + 1) .. (self.modo == "menu" and "  " .. self.nivel or ""))
  local modo = self.modo
  if modo == "menu" then self:desenhar_menu()
  elseif modo == "corridas" then self:desenhar_corridas()
  elseif modo == "oficina" then self:desenhar_oficina()
  elseif modo == "loja" then self:desenhar_loja()
  else self:desenhar_ranking() end
  if self.aviso_t > 0 then
    local w = #self.aviso * 6
    ui.rectfill(240 - w // 2 - 6, 241, 240 + w // 2 + 5, 254, Cores.vinho)
    Menu.centro(self.aviso, 244, Cores.branco)
  end
  if modo == "menu" then
    Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER    O CONSOLE NAO GUARDA O JOGO: ANOTE O PASSWORD")
  else
    Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER   " .. Entrada.NOME.voltar .. ": VOLTAR")
  end
end

return Tela

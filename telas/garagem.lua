-- Garagem do modo historia: o seu carro, dinheiro, ranking e o PASSWORD; daqui sai para a
-- proxima corrida (3 a escolher), a oficina (melhorias), a concessionaria (carros), o ranking e,
-- no 1o lugar, o desafio final (campeonato.lua tem as regras).
local Entrada = require "entrada"
local Cores = require "cores"
local Carros = require "carros"
local Pista = require "pista"
local Menu = require "menu"
local Campeonato = require "campeonato"
local Rapida = require "telas.rapida"
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

function Tela.nova()
  local t = setmetatable({ modo = "menu", aviso = nil, aviso_t = 0, confirmar = nil }, Tela)
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
  self.ficha = Rapida.ficha(m)
  self.carro = string.format("%s   MOTOR %d/3   PNEUS %d/3   BLINDAGEM %d/3", m.nome, e.motor, e.pneus, e.blindagem)
  self.status = string.format("DINHEIRO %s     RANKING %do DE %d (%d PONTOS)", dinheiro(e.dinheiro), pos, #rank, e.pontos)
  local lider = rank[1].jogador and rank[2] or rank[1]
  self.lider = pos == 1 and "VOCE LIDERA O RANKING: O ADVERSARIO TE ESPERA!"
    or string.format("LIDER: %s (%d PONTOS)", lider.nome, lider.pontos)
  self.senha = "PASSWORD: " .. Campeonato.senha_bonita(e)
  self.rank = rank
  self.corridas = Campeonato.corridas(e)

  local opcoes = {
    { texto = "PROXIMA CORRIDA", acao = function() self:ir("corridas") end },
    { texto = "OFICINA (MELHORIAS)", acao = function() self:ir("oficina") end },
    { texto = "CONCESSIONARIA (CARROS)", acao = function() self:ir("loja") end },
    { texto = "RANKING", acao = function() self:ir("ranking") end },
  }
  if Campeonato.desafio_aberto(e) then
    table.insert(opcoes, 1, { texto = "DESAFIO FINAL: O ADVERSARIO", acao = function() self:correr(Campeonato.desafio(e)) end })
  end
  opcoes[#opcoes + 1] = { texto = "SAIR (ANOTE O PASSWORD!)", acao = function() Jogo.ir("titulo") end }
  local escolha = self.menu and self.menu.escolha or 1
  self.menu = Menu.novo(opcoes, 40, 126, 16, 250)
  if escolha <= #opcoes then self.menu.escolha = escolha end

  -- as 3 corridas da rodada
  local lista = {}
  for _, c in ipairs(self.corridas) do
    lista[#lista + 1] = { texto = c.dificuldade.nome .. " - " .. Pista.LISTA[c.pista].nome, acao = function() self:correr(c) end }
  end
  lista[#lista + 1] = { texto = "VOLTAR", acao = function() self:ir("menu") end }
  self.menu_corridas = Menu.novo(lista, 40, 40, 16, 250)

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
  self.menu_oficina = Menu.novo(of, 40, 60, 18, 300)
  self.menu_oficina.escolha = esc_of

  -- concessionaria
  local loja = {}
  for i, mod in ipairs(Carros) do
    loja[#loja + 1] = {
      texto = function()
        if i == e.carro then return string.format("%-8s (O SEU)", mod.nome) end
        return string.format("%-8s %8s  (COM A TROCA: %s)", mod.nome, dinheiro(Campeonato.PRECO_CARRO[mod.id]),
          dinheiro(math.max(0, Campeonato.preco_troca(e, i))))
      end,
      acao = function() self:comprar_carro(i) end,
    }
  end
  loja[#loja + 1] = { texto = "VOLTAR", acao = function() self:ir("menu") end }
  local esc_loja = self.menu_loja and self.menu_loja.escolha or 1
  self.menu_loja = Menu.novo(loja, 40, 40, 14, 330)
  self.menu_loja.escolha = esc_loja
end

function Tela:ir(modo)
  self.modo = modo
  self.confirmar = nil
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
  Jogo.ir("corrida", Campeonato.opcoes_da_corrida(self.e, corrida))
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
  local e = self.e
  local m = Campeonato.modelo(e)
  ui.rectfill(16, 28, 63, 75, Cores.preto)
  ui.tile(Sprites.img.car[m.id .. "_ver"], 0, 20, 32)
  ui.print(self.carro, 76, 32, Cores.branco)
  ui.print(self.ficha, 76, 46, Cores.cinza_claro)
  ui.print(self.status, 76, 64, Cores.amarelo)
  ui.print(self.lider, 76, 80, Cores.cinza_claro)
  self.menu:desenhar()
  ui.rectfill(0, 222, 479, 245, Cores.preto)
  Menu.centro(self.senha, 225, Cores.verde)
  Menu.centro("O CONSOLE NAO GUARDA O JOGO: ANOTE O PASSWORD", 236, Cores.cinza)
end

function Tela:desenhar_corridas()
  self.menu_corridas:desenhar()
  local c = self.corridas[self.menu_corridas.escolha]
  if not c then return end
  local P = C.PREMIOS[c.dificuldade.id]
  local pts = C.PONTOS_RANKING[c.dificuldade.id]
  local y = 126
  ui.print(string.format("PISTA: %s   %d VOLTAS", Pista.LISTA[c.pista].nome, Pista.LISTA[c.pista].voltas), 40, y, Cores.branco)
  ui.print(string.format("PREMIO: 1o %s  2o %s  3o %s   ABATE %s", dinheiro(P.posicao[1]), dinheiro(P.posicao[2]),
    dinheiro(P.posicao[3]), dinheiro(P.abate)), 40, y + 14, Cores.verde)
  ui.print(string.format("PONTOS NO RANKING: 1o +%d  2o +%d  3o +%d   ABATE +%d", pts[1], pts[2], pts[3],
    C.PONTOS_RANKING_ABATE), 40, y + 28, Cores.amarelo)
  ui.print("RIVAIS:", 40, y + 46, Cores.cinza_claro)
  for k, i in ipairs(c.rivais) do
    local p = Campeonato.PILOTOS[i]
    ui.print(string.format("%-10s %s", p[1], Carros[Carros.indice(p[2])].nome), 100, y + 46 + (k - 1) * 12, Cores.branco)
  end
end

function Tela:desenhar_oficina()
  ui.print("MELHORIAS DO SEU " .. Campeonato.modelo(self.e).nome .. "   (" .. dinheiro(self.e.dinheiro) .. ")", 40, 32, Cores.amarelo)
  self.menu_oficina:desenhar()
  ui.print("MOTOR: MAIS VELOCIDADE E ARRANQUE (+4% POR NIVEL)", 40, 150, Cores.cinza_claro)
  ui.print("PNEUS: ESCORREGA MENOS NAS CURVAS", 40, 164, Cores.cinza_claro)
  ui.print("BLINDAGEM: AGUENTA MAIS TIRO, MINA E BATIDA", 40, 178, Cores.cinza_claro)
end

function Tela:desenhar_loja()
  self.menu_loja:desenhar()
  local i = self.menu_loja.escolha
  local mod = Carros[i]
  ui.print("SEU DINHEIRO: " .. dinheiro(self.e.dinheiro), 300, 24, Cores.amarelo)
  if mod then
    ui.rectfill(400, 60, 447, 107, Cores.preto)
    ui.tile(Sprites.img.car[mod.id .. "_ver"], 0, 404, 64)
    Menu.centro(Rapida.ficha(mod), 196, Cores.amarelo)
  end
end

function Tela:desenhar_ranking()
  for i, l in ipairs(self.rank) do
    local cor = l.jogador and Cores.amarelo or Cores.branco
    local col, lin = (i - 1) // 10, (i - 1) % 10
    ui.print(string.format("%2do %-10s %3d", i, l.nome, l.pontos), 60 + col * 200, 40 + lin * 16, cor)
  end
  Menu.centro("1o LUGAR DO RANKING: ABRE O DESAFIO FINAL CONTRA O ADVERSARIO", 214, Cores.cinza_claro)
end

local TITULOS = { menu = "GARAGEM", corridas = "PROXIMA CORRIDA", oficina = "OFICINA",
                  loja = "CONCESSIONARIA", ranking = "RANKING" }

function Tela:desenhar()
  ui.cls(Cores.cinza_escuro)
  Menu.cabecalho(TITULOS[self.modo], "RODADA " .. (self.e.rodada + 1))
  local modo = self.modo
  if modo == "menu" then self:desenhar_menu()
  elseif modo == "corridas" then self:desenhar_corridas()
  elseif modo == "oficina" then self:desenhar_oficina()
  elseif modo == "loja" then self:desenhar_loja()
  else self:desenhar_ranking() end
  if self.aviso_t > 0 then Menu.centro(self.aviso, 208, Cores.vermelho) end
  if modo == "menu" then
    Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER")
  else
    Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER   " .. Entrada.NOME.voltar .. ": VOLTAR")
  end
end

return Tela

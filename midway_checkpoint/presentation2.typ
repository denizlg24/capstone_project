#import "@preview/typslides:1.3.3": *

#show: typslides.with(
  ratio: "16-9",
  theme: "bluey",
  font: "Fira Sans",
  font-size: 20pt,
  link-style: "color",
  show-progress: true,
)

#front-slide(
  title: "Reunião Intermédia 2 · Maio 2026",
  subtitle: [AI Based Compilation for Custom Hardware — Atualização],
  authors: "Deniz Günes",
  info: [Projeto Integrador 25/26, L.EIC, FEUP],
)


#slide(title: "Recap da última reunião intermédia", outlined: true)[
  *Abordagem anterior:* usar a GNN do LISA para gerar labels (_spatial_/_temporal distance_) e fazer #stress[pruning] de literais no SAT-MapIt antes do `solve`.

  - Conversão de DFGs sintéticos para o formato do LISA
  - GNN treinada para produzir 4 labels por nó
  - Adicionavam-se cláusulas $not("lit"_s and "lit"_d)$ quando a distância real excedia a previsão da GNN
  - Resultado preliminar: ~48% de literais pruned, mas redução era essencialmente geométrica
]


#slide(title: "Nova abordagem: partitioned one-shot", outlined: true)[
  Em vez de forçar LISA dentro do SAT-MapIt, #stress[invertemos] a ideia:

  + Pegar num DFG grande 
  + Correr a GNN para obter features por nó
  + Usar essas features para #stress[partir] o grafo em subgrafos
  + Materializar dependências cortadas com operações de memória sintéticas
  + Fazer #stress[one-shot mapping] de cada partição com um SAT mapper simplificado

  #framed[*Resultado:* decomposição temporal entre partições, _mapping_ espacial dentro de cada uma. Sem II, sem KMS, sem _modulo scheduling_.]
]


#slide(title: "Pipeline atual", outlined: true)[
  #framed(title: "5 stages")[
    *DFG generation* → *LISA-GNN inference* → *Partitioning* → *Materialisation* → *SAT mapping*
  ]

  - *DFG generation* — geradores sintéticos (`dfg_gen`) a partir de templates de operações (e.g. matrix multiplication, convolution)
  - *LISA-GNN* — prediz `label0` (prioridade por nó) usada pelo particionador _greedy_
  - *Partitioning* — _greedy_ guiado pela GNN
  - *Materialisation* — cortes de produtores não-`load` viram `u -> synthetic_store` e `synthetic_load -> v`; cortes vindos de `load` são recarregados na partição destino
  - *SAT mapping* — Z3 verifica validade espacial de cada partição
]


#slide(title: "Particionamento", outlined: true)[
  Quando o DFG não cabe num único _config_ do CGRA, dividimos em $P_1, ..., P_K$, impondo:
  $ "partition"("src") <= "partition"("dst") $
  para cada aresta $"src" arrow "dst"$, evitando dependências que voltariam atrás.

  *Greedy partitioner:*
  - Itera sobre nós _ready_
  - Prioridades hand-crafted: #stress[ASAP], #stress[ALAP], _edge count_
  - Critério de qualidade: reduzir arestas cortadas (menos tráfego sintético)
  - Pode usar as predições `label0` da GNN como prioridade
]


#slide(title: "Validação SAT (one-shot)", outlined: true)[
  Para cada partição, $p_(n,e) = 1$ sse o nó $n$ está no PE $e$. Cláusulas:

  - *(C1)* compatibilidade de operação: $"op"(n) in.not "ops"(e) => not p_(n,e)$
  - *(C2)* exatamente um PE por nó: $sum_e p_(n,e) = 1$
  - *(C3)* no máximo uma instrução por PE: $sum_n p_(n,e) <= 1$
  - *(C4)* dependências em ciclo vizinho:
    $ forall (u,v) in E, or.big_(a,b: "nbr"(a,b)) (p_(u,a) and p_(v,b)) $
  - *(C5)* PEs com acesso a memória para `load`/`store`

]


#slide(title: "Exemplo: Matrix Multiplication", outlined: true)[
  #cols(columns: (1fr, 1fr), gutter: 1em)[
    #figure(image("figures/matmul_dfg.png", width: 100%), caption: [DFG sintético])
  ][
    #figure(image("figures/matmul_split.png", width: 100%), caption: [Partições one-shot])
  ]
  Cabe em #stress[2 partições] num CGRA homogéneo $4 times 4$.
]


#slide(title: "Exemplo: Matrix Multiplication — Mapping")[
  #figure(image("figures/matmul_mapping.png", width: 78%), caption: [Mapping das partições no CGRA $4 times 4$])
]


#slide(title: "Exemplo: Convolution", outlined: true)[
  #cols(columns: (1fr, 1fr), gutter: 1em)[
    #figure(image("figures/conv_dfg.png", width: 100%), caption: [DFG sintético de convolução])
  ][
    #figure(image("figures/conv_split.png", width: 100%), caption: [Partições one-shot])
  ]
]


#slide(title: "Exemplo: Convolution — Mapping")[
  #figure(image("figures/conv_mapping.png", width: 78%), caption: [Mapping das partições no CGRA $4 times 4$])
]


#slide(title: "Modelo do CGRA")[
  #figure(image("figures/cgra_4x4.png", width: 60%), caption: [CGRA $4 times 4$: grid de PEs com memória de dados e instruções; cada PE é uma ALU com register file local. Figura de Jeyapaul _et al._ @jeyapaul2011cgra])
]


#slide(title: "Próximos Passos", outlined: true)[
  + *Comparação* — pensar numa equivalência mais formal entre o cenário de one-shot e o de modulo scheduling, para comparar com a abordagem anterior
  + *Escrita do relatório final* — capítulos de validação e conclusões ainda por fechar
]


#let bib = bibliography("refs.bib")
#bibliography-slide(bib)

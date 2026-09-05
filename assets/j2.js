const SIGNATURE=[
  {cat:"Tandoori Pizzas",name:"Tandoori Chicken Pizza"},
  {cat:"Fire Kitchen",name:"Clay-Pot Chicken Biryani"},
  {cat:"Desserts",name:"Molten Chocolate Clay Pot"},
  {cat:"Fire Kitchen",name:"Fire-Roasted Prawns"}
];
const GALLERY=[
  ["1517248135467-4c7edcad34c4","Warm restaurant dining room"],
  ["1565299624946-b28f40a0ae38","Fresh pizza with a crisp baked crust"],
  ["1555939594-58d7cb561ad1","Live fire cooking"],
  ["1414235077428-338989a2e8c0","Restaurant table setting"],
  ["1606313564200-e75d5e30476c","Warm chocolate dessert"],
  ["1551538827-9c037cb4f32a","Fresh signature drink"]
];
const byName=(cat,name)=>MENU[cat].find(x=>x.n===name);
const sig=document.getElementById('signatureGrid');
sig.innerHTML=SIGNATURE.map(s=>{const x=byName(s.cat,s.name);return `<article class="dish-card reveal"><img loading="lazy" src="${IMG(x.i)}" alt="${x.n}" onerror="this.onerror=null;this.src='assets/placeholder.svg'"><div class="dish-body"><div class="dish-kicker">Signature</div><div class="dish-top"><h3>${x.n}</h3><span class="price">MVR ${x.p}</span></div><p>${x.d}</p></div></article>`}).join('');
const cats=Object.keys(MENU),tabs=document.getElementById('tabs'),grid=document.getElementById('menuGrid'),search=document.getElementById('menuSearch');
let activeCat=cats[0];
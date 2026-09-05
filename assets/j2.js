const SIGNATURE=[
  {cat:"Tandoori Pizzas",name:"Tandoori Chicken Pizza"},
  {cat:"Fire Kitchen",name:"Clay-Pot Chicken Biryani"},
  {cat:"Desserts",name:"Molten Chocolate Clay Pot"},
  {cat:"Fire Kitchen",name:"Fire-Roasted Prawns"}
];
const GALLERY=[
  ["1550966871-3ed3cdb5ed0c","Warm restaurant interior with evening lighting"],
  ["1504674900247-0877df9cc836","A table filled with freshly prepared dishes"],
  ["1515003197210-e0cd71810b5f","Colourful fire-kitchen inspired dining spread"],
  ["1766957451060-9d44ef843e82","Candlelit restaurant tables set for an evening meal"],
  ["1547592180-85f173990554","Freshly plated food ready to serve"],
  ["1559339352-11d035aa65de","Restaurant tables prepared for guests"]
];
const byName=(cat,name)=>MENU[cat].find(x=>x.n===name);
const sig=document.getElementById('signatureGrid');
sig.innerHTML=SIGNATURE.map(s=>{const x=byName(s.cat,s.name);return `<article class="dish-card reveal"><img loading="lazy" src="${IMG(x.i)}" alt="${x.n}" onerror="menuImageFallback(this,'${s.cat.replaceAll("'","\\'")}','${x.n.replaceAll("'","\\'")}')"><div class="dish-body"><div class="dish-kicker">Signature</div><div class="dish-top"><h3>${x.n}</h3><span class="price">MVR ${x.p}</span></div><p>${x.d}</p></div></article>`}).join('');
const cats=Object.keys(MENU),tabs=document.getElementById('tabs'),grid=document.getElementById('menuGrid'),search=document.getElementById('menuSearch');
let activeCat=cats[0];
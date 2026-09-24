(function () {
  function openReference() {
    if (window.location.hash === '#reference') {
      const tab = document.querySelector('a[data-value="Reference comparison"]');
      if (tab) tab.click();
    }
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', openReference);
  else openReference();
  function ringFrom(target) { return target.closest('.reference-ring-svg'); }
  function areaFrom(target) { return target.closest('.reference-workbench'); }
  function fitCentre(svg) {
    const width = 1.6 * Number(svg.dataset.tickRadius);
    svg.querySelectorAll('.ref-center-readout text').forEach(text => {
      const base = Number(text.dataset.baseSize);
      text.style.fontSize = base+'px';
      const measured = text.getComputedTextLength();
      if (measured > width) text.style.fontSize = (base*width/measured*.99)+'px';
    });
  }
  function fitAll() { document.querySelectorAll('.reference-ring-svg').forEach(fitCentre); }
  const observer = new MutationObserver(records => {
    records.forEach(record => record.addedNodes.forEach(node => {
      if (node.nodeType !== 1) return;
      if (node.matches('.reference-ring-svg')) fitCentre(node);
      else node.querySelectorAll('.reference-ring-svg').forEach(fitCentre);
    }));
  });
  observer.observe(document.documentElement, {childList:true, subtree:true});
  if (document.fonts) { document.fonts.ready.then(fitAll); document.fonts.addEventListener('loadingdone',fitAll); }
  window.addEventListener('resize', fitAll);
  function ringPosition(svg, event) {
    const p = new DOMPoint(event.clientX,event.clientY).matrixTransform(svg.getScreenCTM().inverse());
    const radius = Math.hypot(p.x,p.y);
    const onRing = svg.dataset.bands.split(',').some(band => {
      const limits = band.split(':').map(Number); return radius >= limits[0] && radius <= limits[1];
    });
    const a = (Math.atan2(p.y,p.x)+Math.PI/2-.075+Math.PI*2)%(Math.PI*2);
    return onRing && a <= 2*Math.PI-.15 ? a : null;
  }
  function pick(el) {
    const area = areaFrom(el), svg = area && area.querySelector('.reference-ring-svg');
    const key = el.dataset.event;
    if (svg && key && window.Shiny) Shiny.setInputValue(svg.dataset.input, key, {priority:'event'});
  }
  document.addEventListener('click', function(e) {
    const el = e.target.closest('[data-event]');
    const svg = ringFrom(e.target);
    if (el && (!svg || ringPosition(svg,e) !== null)) pick(el);
  });
  document.addEventListener('pointermove', function(e) {
    const svg = ringFrom(e.target); if (!svg) return;
    const area = areaFrom(svg), a = ringPosition(svg,e), spoke = svg.querySelector('.ref-spoke');
    if (a === null) { reset(svg); return; }
    const pos = Math.round(a/(Math.PI*2-.15)*Number(svg.dataset.length));
    const angle = a-Math.PI/2+.075;
    spoke.setAttribute('x1',140*Math.cos(angle)); spoke.setAttribute('y1',140*Math.sin(angle));
    spoke.setAttribute('x2',Number(svg.dataset.outer)*Math.cos(angle)); spoke.setAttribute('y2',Number(svg.dataset.outer)*Math.sin(angle));
    spoke.setAttribute('visibility','visible');
    const fmt = pos.toLocaleString('en-US')+' bp';
    svg.querySelector('.ref-center-main').textContent = fmt;
    svg.querySelector('.ref-center-caption').textContent = 'POSITION ON REFERENCE';
    fitCentre(svg);
    area.querySelector('.ref-cursor-pos').textContent = fmt;
    area.querySelectorAll('.ref-readout-row').forEach(row => {
      const calls = Array.from(svg.querySelectorAll('.ref-mark')).filter(m => m.dataset.sample === row.dataset.sample &&
        ((m.dataset.type === 'Insertion' || m.dataset.type === 'Single-base change') ? Math.abs(pos-Number(m.dataset.start)) < Number(svg.dataset.length)*.003 : pos >= Number(m.dataset.start) && pos < Number(m.dataset.end)));
      const windowMark = Array.from(svg.querySelectorAll('.ref-identity-window')).find(m => m.dataset.sample === row.dataset.sample && pos >= Number(m.dataset.start) && pos < Number(m.dataset.end));
      const identityText = windowMark && windowMark.dataset.identity !== '' ? windowMark.dataset.identity+'% identity' : 'No identity score';
      const unique = [...new Set(calls.map(m => m.dataset.type))];
      row.querySelector('.ref-readout-state').textContent = unique.length ? unique.join(' / ')+' · '+identityText : identityText;
      row.querySelector('.ref-readout-dot').style.background = calls.length ? calls[0].dataset.color : windowMark ? windowMark.dataset.color : '#E1E5DC';
    });
  });
  function reset(svg) {
    svg.querySelector('.ref-spoke').setAttribute('visibility','hidden');
    svg.querySelectorAll('.ref-center-readout text').forEach(text => { text.textContent = text.dataset.default; });
    fitCentre(svg);
    const area=areaFrom(svg); area.querySelector('.ref-cursor-pos').textContent='hover the ring';
    area.querySelectorAll('.ref-readout-state').forEach(x=>x.textContent='—');
    area.querySelectorAll('.ref-readout-dot').forEach(x=>x.style.background='#DAD6CD');
  }
  document.addEventListener('pointerout',function(e){const svg=ringFrom(e.target);if(svg && !svg.contains(e.relatedTarget)) reset(svg);});
})();

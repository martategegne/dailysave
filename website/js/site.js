// DailySave Public Website Accessible Interactions & Trilingual Switcher
document.addEventListener('DOMContentLoaded', () => {
  // 1. FAQ Accordion Accessible Toggle
  const faqButtons = document.querySelectorAll('.faq-question');
  faqButtons.forEach((btn) => {
    btn.addEventListener('click', () => {
      const isExpanded = btn.getAttribute('aria-expanded') === 'true';
      const answerId = btn.getAttribute('aria-controls');
      const answer = document.getElementById(answerId);

      btn.setAttribute('aria-expanded', !isExpanded);
      if (answer) {
        answer.hidden = isExpanded;
      }
    });
  });

  // 2. Language Selector
  const langButtons = document.querySelectorAll('.lang-btn');
  const storedLang = localStorage.getItem('dailysave_lang') || 'en';
  setLanguage(storedLang);

  langButtons.forEach((btn) => {
    btn.addEventListener('click', () => {
      const lang = btn.getAttribute('data-lang');
      setLanguage(lang);
      localStorage.setItem('dailysave_lang', lang);
    });
  });

  function setLanguage(lang) {
    document.documentElement.lang = lang;
    langButtons.forEach((btn) => {
      if (btn.getAttribute('data-lang') === lang) {
        btn.classList.add('active');
        btn.setAttribute('aria-pressed', 'true');
      } else {
        btn.classList.remove('active');
        btn.setAttribute('aria-pressed', 'false');
      }
    });

    // Update multilingual text elements
    document.querySelectorAll('[data-en]').forEach((el) => {
      const text = el.getAttribute(`data-${lang}`) || el.getAttribute('data-en');
      if (text) {
        el.textContent = text;
      }
    });
  }
});

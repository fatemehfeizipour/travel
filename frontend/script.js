// Replace this with your API's invoke URL followed by /contact.
// Your stage is $default, so there is no stage name in the address.
const API_URL = "https://62hps6q8l4.execute-api.ca-central-1.amazonaws.com/contact";

const form = document.getElementById("contactForm");
const submitBtn = document.getElementById("submitBtn");
const formMessage = document.getElementById("formMessage");

form.addEventListener("submit", async (event) => {
  event.preventDefault(); // stop the browser's default full-page-reload submit

  const name = document.getElementById("name").value.trim();
  const email = document.getElementById("email").value.trim();
  const phone = document.getElementById("phone").value.trim();
  const message = document.getElementById("message").value.trim();
  const website = document.getElementById("website").value; // honeypot

  // Quick check in the browser. The Lambda checks again, because
  // anyone can send a request without using this page.
  if (!name || !email || !phone || !message) {
    showMessage("Please fill in all required fields.", "error");
    return;
  }

  // The field names here must match what the Lambda reads.
  const payload = { name, email, phone, message, website };

  setLoading(true);

  try {
    const response = await fetch(API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json();

    if (!response.ok) {
      // 4xx: the request was a problem (for example, a missing field).
      // 5xx: something went wrong on our side.
      showMessage(data.message || "Something went wrong.", "error");
      return;
    }

    showMessage(data.message || "Thank you! We will get back to you soon.", "success");
    form.reset();

  } catch (err) {
    console.error("Submission failed:", err);
    showMessage("Network error. Please try again in a moment.", "error");
  } finally {
    setLoading(false);
  }
});

function setLoading(isLoading) {
  submitBtn.disabled = isLoading;
  submitBtn.textContent = isLoading ? "Sending..." : "Send Inquiry";
}

function showMessage(text, type) {
  formMessage.textContent = text;
  formMessage.className = "form-message " + type;
}
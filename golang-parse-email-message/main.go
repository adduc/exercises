package main

import (
	"strings"

	"github.com/mnako/letters"
)

func main() {
	msg := NewMessage()

	// create io.Reader from string
	reader := strings.NewReader(msg)

	parser := letters.NewEmailParser(
		letters.WithFileFilter(letters.NoFiles),
	)

	email, err := parser.Parse(reader)
	if err != nil {
		panic(err)
	}

	println(email.Text)
	println(email.HTML)
	println(len(email.InlineFiles))
	println(len(email.AttachedFiles))
}

func NewMessage() string {
	return "Return-Path: <example@example.com>\r\nReceived: from mail-lj1-f176.google.com (mail-lj1-f176.google.com [209.85.208.176])\r\n by inbound-smtp.us-east-2.amazonaws.com with SMTP id 2p0i54npmg3a7ri5h2t19p43m99vlou92u51ca01\r\n for incoming@example.com;\r\n Fri, 14 Mar 2025 22:58:55 +0000 (UTC)\r\nReceived-SPF: none (spfCheck: 209.85.208.176 is neither permitted nor denied by domain of example.com) client-ip=209.85.208.176; envelope-from=example@example.com; helo=mail-lj1-f176.google.com;\r\nAuthentication-Results: amazonses.com;\r\n spf=none (spfCheck: 209.85.208.176 is neither permitted nor denied by domain of example.com) client-ip=209.85.208.176; envelope-from=example@example.com; helo=mail-lj1-f176.google.com;\r\n dkim=pass header.i=@example-com.20230601.gappssmtp.com;\r\n dmarc=none header.from=example.com;\r\nX-SES-RECEIPT: AEFBQUFBQUFBQUFFb3BRWFgyKzdORUhsZFNKSE9UNGJTVDJ5OCtaUm5SVi9pRnEzbnkrMmZXRmxZbVBaWVBlM2I1ZTlncXhyUnJ4WFBmN29oRzEzd1o5dXVkc3N3aFVHYTFab090RS8xZnI1blZKdnd0V2dYNkhyQ2M5WTMzQ2tQOWVKQVU4MDAvaXZtbVdUVHd3UGhmZDdUVEdlZFBRUVlJTUJ2K1BwUmJYOHFZQ2JpWUV6ZjcxNWJncVRIWnQwVS96c0F0OVJCMnAzYmJhTFZGbjJlSDhHL2dCQ2VYdmhiaVNMbFc1TERrQjBJRjRvZGlLNE42K0lhc2c2V2lKNnVXRm5Xb1JCVnF1SisyVEZyTWhoc0liUThXQzRJcWVFZGFQWUhwY2M2ZExZclc4Sno1Ym1uaXc9PQ==\r\nX-SES-DKIM-SIGNATURE: a=rsa-sha256; q=dns/txt; b=cbjMZeu3kDW9Dd8u6IycTGoldqw8z/0lDBtiaq4+Iiyk/gnOsm2d54Z8Vnl475ZUZjXl+xGVMJIYFHXSYR7qpFSUsRY9ApLjFeS52fGl8Wn1tKLQJPIQ8GdonLu3ywxng7PX+el6gcP4neU6vN+CDkWBQhOWru7rE7v7a4C5VSw=; c=relaxed/simple; s=xplzuhjr4seloozmmorg6obznvt7ijlt; d=amazonses.com; t=1741993136; v=1; bh=0FtpLB4jwm89IAvjTMdg1xmKjzev4rKPmDQvyydLlHU=; h=From:To:Cc:Bcc:Subject:Date:Message-ID:MIME-Version:Content-Type:X-SES-RECEIPT;\r\nReceived: by mail-lj1-f176.google.com with SMTP id 38308e7fff4ca-30bfb6ab47cso25155091fa.3\r\n        for <incoming@example.com>; Fri, 14 Mar 2025 15:58:55 -0700 (PDT)\r\nDKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;\r\n        d=example-com.20230601.gappssmtp.com; s=20230601; t=1741993133; x=1742597933; darn=example.com;\r\n        h=to:subject:message-id:date:from:mime-version:from:to:cc:subject\r\n         :date:message-id:reply-to;\r\n        bh=0FtpLB4jwm89IAvjTMdg1xmKjzev4rKPmDQvyydLlHU=;\r\n        b=ioBWeCPpXnxlj/T0LdZ6f8UEZlHgLaqW2mB464kFNEWlmIzusZeG+tH1vGgMr8BRLt\r\n         Vzb5n0vFway8P4Knu7cV7W+s9sD/K1HB+wwFze2on4mLbdgDjvKV+jV9xHQ9jjVdmJtQ\r\n         0IdgQ3FDnAYUAbiWul2l+U1sXzTfH3TUiPBufaEuosRlM+bkorQPzg6SRRIqR3YwEjd+\r\n         Mk5vvXZ/Ldv5Dn32r7Gv59h0qiYg2xvhwRZk6rK+mPJHWJdGWMBa5C5TjuzSCr7A4K0Y\r\n         z1gBkm7NgqOGjk8Fm41FkNpZc9pZ9G8f4xGG0Xfw+qtqLMVBGZ4oAaMkACiOjKqeUI6y\r\n         hq0w==\r\nX-Google-DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;\r\n        d=1e100.net; s=20230601; t=1741993133; x=1742597933;\r\n        h=to:subject:message-id:date:from:mime-version:x-gm-message-state\r\n         :from:to:cc:subject:date:message-id:reply-to;\r\n        bh=0FtpLB4jwm89IAvjTMdg1xmKjzev4rKPmDQvyydLlHU=;\r\n        b=bl/xfAiv6UaRFpmIM7RXoxQTu0y6vphysM/0OwI9vbq9157kC4OCCKOyILTyYbvcTE\r\n         9CZ+odZsrLJ0EIV8HOSQsf47LgpCbqzH7kCUFPkSvZOQsvTTbzkPifLSscDuCArDAGmj\r\n         r+e5hktPt5b3BLlU/caZtmNbL31bJ5iZrkPcP7hLd/3+lTcwJNv7Q/p0gm79m09QvBbQ\r\n         t8UViUNO/Ad6IcT01ntOoCBjW+TcRnzoV4K3jTi8r47+iDXyClP4fIlFBoFXAXcioh51\r\n         eJoOSQFnfufwZgtq2ipI/Qagsv9Sws4pgFjm9g0/SM40BipkZBVxW+0sseS6ibs5V80D\r\n         mFtA==\r\nX-Gm-Message-State: AOJu0YxQLJQQMK0zAbBgJWZIEX6lQt17cSyohRZ2GadZgN9A8Mm7SoUn\r\n\t0+lJsw+4jCZZNPxRNXcq2PdZ1moWhq8yLfoiJhNNLiqT76gO2g41a0M4EBEDMpyvdb9NYFypOru\r\n\tJaQfCEcG1OyxIn1wSJJQZu/2ADCsWGAxSowKaU9jYPPoPHKmfjQ==\r\nX-Gm-Gg: ASbGncuzPUHbVKpIJKguEjuUEPdIqu7t8cjeYcdNi5Wrw85cpzTk7+eZ1H75xC2I+cG\r\n\ttpTPTaldJ8gjIkSvkp4RSytnlRRWKCnxDCxM8RVGf0eXqn+TbQDC0deyHnpb34pi61pP64GYLm2\r\n\tt8WLhy6l4Yo/1kz3kTggws7xdBBWFCGhmK6ggTot0V\r\nX-Google-Smtp-Source: AGHT+IERErTwdLuYkZ1sTNSdvVMxTOg+LKTl94Vm/WBuQUXgU3OhAZrYOy52WsKSCYu0oTb4lk8VBAS1ZjexEgLtX8c=\r\nX-Received: by 2002:a05:6512:3082:b0:545:d7d:ac53 with SMTP id\r\n 2adb3069b0e04-549c398cffbmr1562477e87.34.1741993133037; Fri, 14 Mar 2025\r\n 15:58:53 -0700 (PDT)\r\nMIME-Version: 1.0\r\nFrom: Example User <example@example.com>\r\nDate: Fri, 14 Mar 2025 17:58:42 -0500\r\nX-Gm-Features: AQ5f1JraLW0GPlmRQ61YonwYP6XPAR1NMU8O0vkGJM3QkzeUhFV_Wq72V6wSYsE\r\nMessage-ID: <CA+8DwmEX7ctu1TCP5odnKpRaGXpztDQ44esV7OWz9MFFZ1BeKg@mail.gmail.com>\r\nSubject: test email 9\r\nTo: incoming@example.com\r\nContent-Type: multipart/alternative; boundary=\"000000000000e577ae063055612e\"\r\n\r\n--000000000000e577ae063055612e\r\nContent-Type: text/plain; charset=\"UTF-8\"\r\n\r\nThis is the ninth test email\r\n\r\n--000000000000e577ae063055612e\r\nContent-Type: text/html; charset=\"UTF-8\"\r\n\r\n<div dir=\"ltr\">This is the ninth test email</div>\r\n\r\n--000000000000e577ae063055612e--\r\n"
}

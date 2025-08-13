package main

import (
	"log"
	"os"

	"github.com/tebeka/selenium"
	"github.com/tebeka/selenium/chrome"
)

func main() {
	cdPath := os.Getenv("CHROMEDRIVER_PATH")
	if cdPath == "" {
		cdPath = "chromedriver"
	}

	service, err := selenium.NewChromeDriverService(cdPath, 4444)
	if err != nil {
		log.Fatal("Error:", err)
	}
	defer service.Stop()

	caps := selenium.Capabilities{}
	caps.AddChrome(chrome.Capabilities{Args: []string{"--headless"}})

	driver, err := selenium.NewRemote(caps, "")

	if err != nil {
		log.Fatal("Error:", err)
	}

	err = driver.Get("https://www.selenium.dev/selenium/web/inputs.html")
	if err != nil {
		log.Fatal("Error:", err)
	}

	elements, err := driver.FindElements(selenium.ByName, "checkbox_input")
	if err != nil {
		log.Fatal("Error:", err)
	}

	for _, element := range elements {
		selected, err := element.IsSelected()
		if err != nil {
			log.Fatal("Error:", err)
		}

		if selected {
			log.Printf("✅ Element is selected")
		} else {
			log.Fatalf("❌ Element is not selected")
		}

		log.Printf("Unselect element")
		err = element.Click()
		if err != nil {
			log.Fatal("Error:", err)
		}

		selected, err = element.IsSelected()
		if err != nil {
			return
		}

		if !selected {
			log.Printf("✅ Not selected")
		} else {
			log.Fatalf("❌ Element is selected")
		}

	}
}

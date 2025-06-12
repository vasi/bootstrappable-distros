;; -*- mode: scheme; -*-

(use-modules (gnu))
(use-service-modules networking ssh)
(use-package-modules ssh)

(define %my-services
  (modify-services %base-services
    (guix-service-type config =>
      (guix-configuration
        (inherit config)
        (use-substitutes? #f)))))

(operating-system
  (host-name "guix")
  (timezone "America/Toronto")
  (locale "en_US.utf8")

  (bootloader (bootloader-configuration
               (bootloader grub-efi-bootloader)
               (targets '("/boot/efi"))))
  (file-systems (append
                 (list (file-system
                        (device (file-system-label "my-root"))
                        (mount-point "/")
                        (type "ext4"))
                   (file-system
                     (device (file-system-label "GNU-ESP"))
                     (mount-point "/boot/efi")
                     (type "vfat")))
                 %base-file-systems))

  (users (cons (user-account
                (name "vasi")
                (group "users")
                (supplementary-groups '("wheel"
                                        "audio"
                                        "video")))
          %base-user-accounts))

  (packages %base-packages)

  (services (append (list (service dhcp-client-service-type)
                     (service openssh-service-type
                       (openssh-configuration
                         (openssh openssh-sans-x)
                         (port-number 22))))
             %my-services)))

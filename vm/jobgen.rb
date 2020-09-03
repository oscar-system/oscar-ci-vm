require "rexml/document"

module JobGen
  class <<self
    include REXML

    def find_element(node, name)
      if node.has_elements? then
        node.each_element do | e |
          if e.name == name then
            e.delete_at(0)
            return e
          end
          e2 = find_element(e, name)
          return e2 if e2
        end
      end
      return nil
    end

    def gen_jenkinsfile(path)
      e = Element.new("scriptPath")
      e.add_text(path)
      return e
    end

    def gen_branch(name)
      e = Element.new("name")
      e.add_text("*/#{name}")
      return e
    end

    def gen_repo(url)
      e = Element.new("url")
      e.add_text(url)
      return e
    end

    def gen_timer(timer_spec)
      e = Element.new("hudson.triggers.TimerTrigger")
      e2 = Element.new("spec")
      e.add_element(e2)
      e2.add_text(timer_spec)
      return e
    end

    def gen_string_parameter(name, desc, default)
      e = Element.new("hudson.model.StringParameterDefinition")
      ename = Element.new("name")
      ename.add_text(name)
      e.add_element(ename)
      edesc = Element.new("description")
      edesc.add_text(desc) if desc
      e.add_element(edesc)
      edefault = Element.new("defaultValue")
      edefault.add_text(default)
      e.add_element(edefault)
      etrim = Element.new("trim")
      etrim.add_text("true")
      e.add_element(etrim)
      return e
    end

    def gen_choices(choices)
      e = Element.new("choices")
      e.add_attribute("class", "java.util.Arrays$ArrayList")
      eanchor = Element.new("a")
      eanchor.add_attribute("class", "string-array")
      e.add_element(eanchor)
      for choice in choices do
        eitem = Element.new("string")
        eitem.add_text(choice)
        eanchor.add_element(eitem)
      end
      return e
    end

    def gen_choice_parameter(name, desc, options)
      e = Element.new("hudson.model.ChoiceParameterDefinition")
      ename = Element.new("name")
      ename.add_text(name)
      e.add_element(ename)
      edesc = Element.new("description")
      edesc.add_text(desc) if desc
      e.add_element(edesc)
      e.add_element(gen_choices(options))
      return e
    end

    def gen_parameters(parameters)
      e = Element.new("parameterDefinitions")
      for spec in parameters do
        if spec["string"] != nil then
          e.add_element(gen_string_parameter(spec["name"], spec["desc"],
            spec["string"].to_s))
        else
          e.add_element(gen_choice_parameter(spec["name"], spec["desc"],
            spec["options"]))
        end
      end
      return e
    end

    def make_config(jobname, spec)
      timer = spec["timer"]
      jfile = spec["jenkinsfile"]
      repo = jfile["repo"]
      branch = jfile["branch"] || "master"
      path = jfile["path"] || "Jenkinsfile"
      parameters = spec["parameters"] || []

      template = Document.new(File.read("#{__dir__}/config.tmpl"))
      el_parameters = find_element(template, "patch.PARAMETERS")
      el_timer = find_element(template, "patch.TIMER")
      el_repo = find_element(template, "patch.REPO")
      el_branch = find_element(template, "patch.BRANCH")
      el_jenkinsfile = find_element(template, "patch.JENKINSFILE")

      el_parameters.replace_with(gen_parameters(parameters))
      if timer then
        el_timer.replace_with(gen_timer("H/30 * * * *"))
      else
        el_timer.parent.delete(el_timer)
      end
      el_repo.replace_with(gen_repo("https://github.com/oscar-system/oscar-ci"))
      el_branch.replace_with(gen_branch("master"))
      el_jenkinsfile.replace_with(gen_jenkinsfile("Jenkinsfile"))

      output = ""
      formatter = Formatters::Pretty.new(2)
      formatter.compact = true
      formatter.write(template, output)
      return output
    end
  end

end
